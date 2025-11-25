#!/usr/bin/env python3
"""
Sistema de Coleta de Dados do iNaturalist para Insetos
Coleta dados e imagens de insetos catalogados no iNaturalist para treinamento de modelos de IA
"""

import os
import sys
import json
import time
import requests
import argparse
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple
import logging
from urllib.parse import urlencode
from PIL import Image
import io
import hashlib
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('inaturalist_collector.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Configurar UTF-8 no Windows
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

# Classes de insetos alvo (baseadas no train_model.py)
TARGET_CLASSES = [
    'aranhas', 'besouro_carabideo', 'crisopideo', 'joaninhas',
    'libelulas', 'mosca_asilidea', 'mosca_dolicopodidea',
    'mosca_sirfidea', 'mosca_taquinidea', 'percevejo_geocoris',
    'percevejo_orius', 'percevejo_pentatomideo', 'percevejo_reduviideo',
    'tesourinha', 'vespa_parasitoide', 'vespa_predadora'
]

# Mapeamento de nomes científicos para classes do projeto
SCIENTIFIC_NAME_MAPPING = {
    # Aranhas
    'Araneae': 'aranhas',
    'Araneidae': 'aranhas',
    'Salticidae': 'aranhas',
    'Thomisidae': 'aranhas',
    'Lycosidae': 'aranhas',

    # Besouros Carabídeos
    'Carabidae': 'besouro_carabideo',
    'Carabus': 'besouro_carabideo',
    'Calosoma': 'besouro_carabideo',
    'Cicindela': 'besouro_carabideo',

    # Crisopídeos
    'Chrysopidae': 'crisopideo',
    'Chrysopa': 'crisopideo',
    'Chrysoperla': 'crisopideo',

    # Joaninhas
    'Coccinellidae': 'joaninhas',
    'Coccinella': 'joaninhas',
    'Harmonia': 'joaninhas',
    'Hippodamia': 'joaninhas',

    # Libélulas
    'Odonata': 'libelulas',
    'Libellulidae': 'libelulas',
    'Aeshnidae': 'libelulas',
    'Coenagrionidae': 'libelulas',

    # Moscas Asilídeas
    'Asilidae': 'mosca_asilidea',
    'Asilus': 'mosca_asilidea',
    'Laphria': 'mosca_asilidea',

    # Moscas Dolichopodídeas
    'Dolichopodidae': 'mosca_dolicopodidea',
    'Dolichopus': 'mosca_dolicopodidea',
    'Medetera': 'mosca_dolicopodidea',

    # Moscas Sirfídeas
    'Syrphidae': 'mosca_sirfidea',
    'Eristalis': 'mosca_sirfidea',
    'Syrphus': 'mosca_sirfidea',
    'Helophilus': 'mosca_sirfidea',

    # Moscas Taquinídeas
    'Tachinidae': 'mosca_taquinidea',
    'Tachina': 'mosca_taquinidea',
    'Exorista': 'mosca_taquinidea',

    # Percevejos Geocoris
    'Geocoris': 'percevejo_geocoris',
    'Geocoris punctipes': 'percevejo_geocoris',

    # Percevejos Orius
    'Orius': 'percevejo_orius',
    'Orius insidiosus': 'percevejo_orius',

    # Percevejos Pentatomídeos
    'Pentatomidae': 'percevejo_pentatomideo',
    'Nezara': 'percevejo_pentatomideo',
    'Euschistus': 'percevejo_pentatomideo',

    # Percevejos Reduviídeos
    'Reduviidae': 'percevejo_reduviideo',
    'Zelus': 'percevejo_reduviideo',
    'Apiomerus': 'percevejo_reduviideo',

    # Tesourinhas
    'Dermaptera': 'tesourinha',
    'Forficulidae': 'tesourinha',
    'Forficula': 'tesourinha',

    # Vespas Parasitoides
    'Ichneumonidae': 'vespa_parasitoide',
    'Braconidae': 'vespa_parasitoide',
    'Chalcididae': 'vespa_parasitoide',
    'Trichogrammatidae': 'vespa_parasitoide',

    # Vespas Predadoras
    'Vespidae': 'vespa_predadora',
    'Polistes': 'vespa_predadora',
    'Vespula': 'vespa_predadora',
    'Dolichovespula': 'vespa_predadora'
}


class iNaturalistCollector:
    """Coletor de dados do iNaturalist"""

    def __init__(self, output_dir: str = "enhanced_insect_data", api_key: Optional[str] = None):
        self.base_url = "https://api.inaturalist.org/v1"
        self.output_dir = Path(output_dir)
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Guia-inNatFlu/1.0 (Educational Research)',
            'Accept': 'application/json'
        })

        # Criar diretórios de saída
        self._create_output_directories()

        # Controle de rate limiting
        self.last_request_time = 0
        self.min_request_interval = 0.1  # 100ms entre requests

        # Estatísticas
        self.stats = {
            'total_observations': 0,
            'total_images': 0,
            'successful_downloads': 0,
            'failed_downloads': 0,
            'duplicates_skipped': 0,
            'quality_filtered': 0
        }

        # Lock para thread safety
        self.lock = threading.Lock()

    def _create_output_directories(self):
        """Cria diretórios de saída para cada classe"""
        for class_name in TARGET_CLASSES:
            class_dir = self.output_dir / "raw_data" / class_name
            class_dir.mkdir(parents=True, exist_ok=True)

        # Diretório para metadados
        (self.output_dir / "metadata").mkdir(parents=True, exist_ok=True)

    def _rate_limit(self):
        """Implementa rate limiting para respeitar limites da API"""
        current_time = time.time()
        time_since_last = current_time - self.last_request_time

        if time_since_last < self.min_request_interval:
            time.sleep(self.min_request_interval - time_since_last)

        self.last_request_time = time.time()

    def _make_request(self, endpoint: str, params: Dict) -> Optional[Dict]:
        """Faz requisição para a API do iNaturalist com rate limiting"""
        self._rate_limit()

        url = f"{self.base_url}/{endpoint}"

        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()

        except requests.exceptions.RequestException as e:
            logger.error(f"Erro na requisição para {url}: {e}")
            return None

    def search_observations(self, taxon_name: str, quality_grade: str = "research",
                            per_page: int = 200, max_pages: int = 10) -> List[Dict]:
        """Busca observações por nome científico"""
        observations = []

        for page in range(1, max_pages + 1):
            params = {
                'q': taxon_name,
                'quality_grade': quality_grade,
                'has_photos': True,
                'per_page': per_page,
                'page': page,
                'order': 'desc',
                'order_by': 'created_at'
            }

            logger.info(f"Buscando página {page} para {taxon_name}...")
            data = self._make_request('observations', params)

            if not data or 'results' not in data:
                logger.warning(
                    f"Nenhum resultado encontrado para {taxon_name} na página {page}")
                break

            page_observations = data['results']
            observations.extend(page_observations)

            # Se retornou menos que o esperado, provavelmente é a última página
            if len(page_observations) < per_page:
                break

            logger.info(
                f"Encontradas {len(page_observations)} observações na página {page}")

        logger.info(
            f"Total de {len(observations)} observações encontradas para {taxon_name}")
        return observations

    def get_taxon_info(self, taxon_id: int) -> Optional[Dict]:
        """Obtém informações detalhadas de um táxon"""
        params = {'id': taxon_id}
        data = self._make_request('taxa', params)

        if data and 'results' in data and data['results']:
            return data['results'][0]
        return None

    def classify_observation(self, observation: Dict) -> Optional[str]:
        """Classifica uma observação baseada no táxon"""
        if 'taxon' not in observation:
            return None

        taxon = observation['taxon']

        # Tentar mapear pelo nome científico
        scientific_name = taxon.get('name', '')
        for sci_name, class_name in SCIENTIFIC_NAME_MAPPING.items():
            if sci_name.lower() in scientific_name.lower():
                return class_name

        # Tentar mapear pelo nome comum
        common_names = taxon.get('preferred_common_name', '')
        if common_names:
            common_lower = common_names.lower()
            if 'spider' in common_lower or 'aranha' in common_lower:
                return 'aranhas'
            elif 'ladybug' in common_lower or 'joaninha' in common_lower:
                return 'joaninhas'
            elif 'dragonfly' in common_lower or 'libélula' in common_lower:
                return 'libelulas'
            elif 'wasp' in common_lower or 'vespa' in common_lower:
                if 'parasitoid' in common_lower or 'ichneumon' in common_lower:
                    return 'vespa_parasitoide'
                else:
                    return 'vespa_predadora'

        return None

    def download_image(self, photo_url: str, output_path: Path) -> bool:
        """Baixa uma imagem da URL fornecida"""
        max_retries = 3
        retry_delay = 1.0

        for attempt in range(max_retries):
            try:
                response = self.session.get(photo_url, timeout=30)
                response.raise_for_status()

                # Verificar se é realmente uma imagem
                content_type = response.headers.get('content-type', '')
                if not content_type.startswith('image/'):
                    logger.warning(f"URL não é uma imagem: {photo_url}")
                    return False

                # Salvar imagem com retry em caso de conflito
                for save_attempt in range(max_retries):
                    try:
                        # Usar modo exclusivo para evitar conflitos
                        with open(output_path, 'xb') as f:
                            f.write(response.content)
                        break
                    except FileExistsError:
                        # Arquivo já existe, pular
                        return True
                    except PermissionError:
                        if save_attempt < max_retries - 1:
                            time.sleep(retry_delay)
                            continue
                        else:
                            logger.warning(
                                f"Erro de permissão ao salvar {output_path}")
                            return False

                # Verificar se a imagem é válida (com retry)
                for verify_attempt in range(max_retries):
                    try:
                        # Aguardar um pouco para garantir que o arquivo foi fechado
                        time.sleep(0.1)

                        with Image.open(output_path) as img:
                            img.verify()

                        # Verificar tamanho mínimo
                        with Image.open(output_path) as img:
                            if img.size[0] < 100 or img.size[1] < 100:
                                logger.warning(
                                    f"Imagem muito pequena: {output_path}")
                                try:
                                    os.remove(output_path)
                                except:
                                    pass
                                return False

                        return True

                    except (OSError, PermissionError) as e:
                        if verify_attempt < max_retries - 1:
                            time.sleep(retry_delay)
                            continue
                        else:
                            logger.warning(
                                f"Erro ao verificar imagem {output_path}: {e}")
                            try:
                                os.remove(output_path)
                            except:
                                pass
                            return False
                    except Exception as e:
                        logger.warning(f"Imagem inválida {output_path}: {e}")
                        try:
                            os.remove(output_path)
                        except:
                            pass
                        return False

            except Exception as e:
                if attempt < max_retries - 1:
                    logger.warning(
                        f"Tentativa {attempt + 1} falhou para {photo_url}: {e}")
                    time.sleep(retry_delay)
                    continue
                else:
                    logger.error(
                        f"Erro ao baixar {photo_url} após {max_retries} tentativas: {e}")
                    return False

        return False

    def process_observation(self, observation: Dict, class_name: str) -> Dict:
        """Processa uma observação e baixa suas imagens"""
        result = {
            'observation_id': observation.get('id'),
            'class': class_name,
            'taxon_name': observation.get('taxon', {}).get('name', ''),
            'common_name': observation.get('taxon', {}).get('preferred_common_name', ''),
            'location': observation.get('place_guess', ''),
            'coordinates': observation.get('location', ''),
            'observed_on': observation.get('observed_on', ''),
            'images': [],
            'metadata': observation
        }

        photos = observation.get('photos', [])
        if not photos:
            return result

        class_dir = self.output_dir / "raw_data" / class_name

        for i, photo in enumerate(photos):
            photo_url = photo.get('url', '')
            if not photo_url:
                continue

            # Gerar nome único para a imagem
            image_hash = hashlib.md5(photo_url.encode()).hexdigest()[:8]
            filename = f"{class_name}_{observation['id']}_{i}_{image_hash}.jpg"
            output_path = class_dir / filename

            # Pular se já existe
            if output_path.exists():
                with self.lock:
                    self.stats['duplicates_skipped'] += 1
                continue

            # Baixar imagem
            if self.download_image(photo_url, output_path):
                result['images'].append(str(output_path))
                with self.lock:
                    self.stats['successful_downloads'] += 1
                    self.stats['total_images'] += 1
            else:
                with self.lock:
                    self.stats['failed_downloads'] += 1

        return result

    def collect_data_for_class(self, class_name: str, max_observations: int = 1000) -> List[Dict]:
        """Coleta dados para uma classe específica"""
        logger.info(f"Coletando dados para classe: {class_name}")

        # Buscar termos de busca para esta classe
        search_terms = self._get_search_terms_for_class(class_name)

        all_observations = []

        for term in search_terms:
            logger.info(f"Buscando por: {term}")
            observations = self.search_observations(term, max_pages=5)

            # Filtrar observações para esta classe
            class_observations = []
            for obs in observations:
                if self.classify_observation(obs) == class_name:
                    class_observations.append(obs)

            all_observations.extend(class_observations)

            # Limitar número total
            if len(all_observations) >= max_observations:
                break

        # Processar observações
        processed_data = []

        # Reduzir workers para evitar conflitos no Windows
        with ThreadPoolExecutor(max_workers=2) as executor:
            futures = []

            for obs in all_observations[:max_observations]:
                future = executor.submit(
                    self.process_observation, obs, class_name)
                futures.append(future)

            for future in as_completed(futures):
                try:
                    result = future.result()
                    if result['images']:  # Só adicionar se tem imagens
                        processed_data.append(result)
                        with self.lock:
                            self.stats['total_observations'] += 1

                    # Pequeno delay para reduzir conflitos
                    time.sleep(0.1)

                except Exception as e:
                    logger.error(f"Erro ao processar observação: {e}")

        logger.info(
            f"Coletadas {len(processed_data)} observações com imagens para {class_name}")
        return processed_data

    def _get_search_terms_for_class(self, class_name: str) -> List[str]:
        """Retorna termos de busca para uma classe específica"""
        search_terms = {
            'aranhas': ['Araneae', 'spider', 'aranha'],
            'besouro_carabideo': ['Carabidae', 'ground beetle', 'besouro carabídeo'],
            'crisopideo': ['Chrysopidae', 'green lacewing', 'crisopídeo'],
            'joaninhas': ['Coccinellidae', 'ladybug', 'joaninha'],
            'libelulas': ['Odonata', 'dragonfly', 'libélula'],
            'mosca_asilidea': ['Asilidae', 'robber fly', 'mosca asilídea'],
            'mosca_dolicopodidea': ['Dolichopodidae', 'long-legged fly', 'mosca dolichopodídea'],
            'mosca_sirfidea': ['Syrphidae', 'hoverfly', 'mosca sirfídea'],
            'mosca_taquinidea': ['Tachinidae', 'tachinid fly', 'mosca taquinídea'],
            'percevejo_geocoris': ['Geocoris', 'big-eyed bug', 'percevejo geocoris'],
            'percevejo_orius': ['Orius', 'minute pirate bug', 'percevejo orius'],
            'percevejo_pentatomideo': ['Pentatomidae', 'stink bug', 'percevejo pentatomídeo'],
            'percevejo_reduviideo': ['Reduviidae', 'assassin bug', 'percevejo reduviídeo'],
            'tesourinha': ['Dermaptera', 'earwig', 'tesourinha'],
            'vespa_parasitoide': ['Ichneumonidae', 'Braconidae', 'parasitoid wasp', 'vespa parasitoide'],
            'vespa_predadora': ['Vespidae', 'Polistes', 'predatory wasp', 'vespa predadora']
        }

        return search_terms.get(class_name, [class_name])

    def save_metadata(self, class_name: str, data: List[Dict]):
        """Salva metadados das observações coletadas"""
        metadata_file = self.output_dir / \
            "metadata" / f"{class_name}_metadata.json"

        metadata = {
            'class_name': class_name,
            'collection_date': datetime.now().isoformat(),
            'total_observations': len(data),
            'total_images': sum(len(obs['images']) for obs in data),
            'observations': data
        }

        with open(metadata_file, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)

        logger.info(f"Metadados salvos em: {metadata_file}")

    def collect_all_data(self, max_observations_per_class: int = 1000):
        """Coleta dados para todas as classes"""
        logger.info("Iniciando coleta de dados para todas as classes...")

        all_data = {}

        for class_name in TARGET_CLASSES:
            try:
                data = self.collect_data_for_class(
                    class_name, max_observations_per_class)
                all_data[class_name] = data
                self.save_metadata(class_name, data)

                # Pequena pausa entre classes
                time.sleep(2)

            except Exception as e:
                logger.error(f"Erro ao coletar dados para {class_name}: {e}")
                continue

        # Salvar estatísticas gerais
        self.save_collection_stats(all_data)

        logger.info("Coleta de dados concluída!")
        self.print_stats()

    def save_collection_stats(self, all_data: Dict):
        """Salva estatísticas da coleta"""
        stats_file = self.output_dir / "metadata" / "collection_stats.json"

        stats_data = {
            'collection_date': datetime.now().isoformat(),
            'total_classes': len(TARGET_CLASSES),
            'classes_collected': list(all_data.keys()),
            'statistics': self.stats,
            'class_summary': {}
        }

        for class_name, data in all_data.items():
            stats_data['class_summary'][class_name] = {
                'observations': len(data),
                'images': sum(len(obs['images']) for obs in data)
            }

        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(stats_data, f, indent=2, ensure_ascii=False)

        logger.info(f"Estatísticas salvas em: {stats_file}")

    def print_stats(self):
        """Imprime estatísticas da coleta"""
        print("\n" + "="*50)
        print("ESTATÍSTICAS DA COLETA")
        print("="*50)
        print(f"Observações processadas: {self.stats['total_observations']}")
        print(f"Imagens baixadas: {self.stats['total_images']}")
        print(f"Downloads bem-sucedidos: {self.stats['successful_downloads']}")
        print(f"Downloads falharam: {self.stats['failed_downloads']}")
        print(f"Duplicatas ignoradas: {self.stats['duplicates_skipped']}")
        print(f"Filtradas por qualidade: {self.stats['quality_filtered']}")
        print("="*50)


def main():
    parser = argparse.ArgumentParser(
        description='Coletor de dados do iNaturalist')
    parser.add_argument('--output-dir', default='enhanced_insect_data',
                        help='Diretório de saída')
    parser.add_argument('--class', dest='target_class',
                        help='Classe específica para coletar (opcional)')
    parser.add_argument('--max-observations', type=int, default=1000,
                        help='Máximo de observações por classe')
    parser.add_argument('--api-key',
                        help='Chave da API do iNaturalist (opcional)')

    args = parser.parse_args()

    # Criar coletor
    collector = iNaturalistCollector(args.output_dir, args.api_key)

    if args.target_class:
        if args.target_class not in TARGET_CLASSES:
            print(f"Classe inválida: {args.target_class}")
            print(f"Classes disponíveis: {', '.join(TARGET_CLASSES)}")
            return

        # Coletar dados para uma classe específica
        data = collector.collect_data_for_class(
            args.target_class, args.max_observations)
        collector.save_metadata(args.target_class, data)
        collector.print_stats()
    else:
        # Coletar dados para todas as classes
        collector.collect_all_data(args.max_observations)


if __name__ == '__main__':
    main()
