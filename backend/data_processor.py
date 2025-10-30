#!/usr/bin/env python3
"""
Processador de Dados Coletados do iNaturalist
Processa, valida e organiza os dados coletados para treinamento de modelos
"""

import os
import sys
import json
import shutil
import argparse
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import logging
from datetime import datetime
import cv2
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
import hashlib
from collections import Counter
import matplotlib.pyplot as plt
import seaborn as sns

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_processor.log'),
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

# Classes de insetos alvo
TARGET_CLASSES = [
    'aranhas', 'besouro_carabideo', 'crisopideo', 'joaninhas',
    'libelulas', 'mosca_asilidea', 'mosca_dolicopodidea',
    'mosca_sirfidea', 'mosca_taquinidea', 'percevejo_geocoris',
    'percevejo_orius', 'percevejo_pentatomideo', 'percevejo_reduviideo',
    'tesourinha', 'vespa_parasitoide', 'vespa_predadora'
]


class ImageQualityValidator:
    """Validador de qualidade de imagens"""

    def __init__(self, min_size: Tuple[int, int] = (100, 100),
                 max_blur_threshold: float = 100.0,
                 min_brightness: float = 0.1,
                 max_brightness: float = 0.9):
        self.min_size = min_size
        self.max_blur_threshold = max_blur_threshold
        self.min_brightness = min_brightness
        self.max_brightness = max_brightness

    def validate_image(self, image_path: Path) -> Dict:
        """Valida a qualidade de uma imagem"""
        result = {
            'path': str(image_path),
            'valid': True,
            'issues': [],
            'quality_score': 0.0,
            'size': (0, 0),
            'blur_score': 0.0,
            'brightness': 0.0
        }

        try:
            # Carregar imagem
            image = cv2.imread(str(image_path))
            if image is None:
                result['valid'] = False
                result['issues'].append('Não foi possível carregar a imagem')
                return result

            # Converter para RGB
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            height, width = image_rgb.shape[:2]
            result['size'] = (width, height)

            # Verificar tamanho mínimo
            if width < self.min_size[0] or height < self.min_size[1]:
                result['valid'] = False
                result['issues'].append(
                    f'Tamanho muito pequeno: {width}x{height}')

            # Verificar blur
            blur_score = self._calculate_blur_score(image_rgb)
            result['blur_score'] = blur_score
            if blur_score < self.max_blur_threshold:
                result['valid'] = False
                result['issues'].append(
                    f'Imagem muito desfocada: {blur_score:.2f}')

            # Verificar brilho
            brightness = self._calculate_brightness(image_rgb)
            result['brightness'] = brightness
            if brightness < self.min_brightness or brightness > self.max_brightness:
                result['valid'] = False
                result['issues'].append(f'Brilho inadequado: {brightness:.2f}')

            # Calcular score de qualidade
            result['quality_score'] = self._calculate_quality_score(
                blur_score, brightness, width, height)

        except Exception as e:
            result['valid'] = False
            result['issues'].append(f'Erro na validação: {str(e)}')

        return result

    def _calculate_blur_score(self, image: np.ndarray) -> float:
        """Calcula score de blur usando Laplacian"""
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        return cv2.Laplacian(gray, cv2.CV_64F).var()

    def _calculate_brightness(self, image: np.ndarray) -> float:
        """Calcula brilho médio da imagem"""
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        return np.mean(gray) / 255.0

    def _calculate_quality_score(self, blur_score: float, brightness: float,
                                 width: int, height: int) -> float:
        """Calcula score geral de qualidade"""
        # Normalizar blur score (0-1)
        blur_norm = min(blur_score / 1000.0, 1.0)

        # Score de brilho (preferir valores médios)
        brightness_score = 1.0 - abs(brightness - 0.5) * 2

        # Score de tamanho (preferir imagens maiores)
        size_score = min((width * height) / (500 * 500), 1.0)

        # Score combinado
        return (blur_norm * 0.4 + brightness_score * 0.3 + size_score * 0.3)


class DataProcessor:
    """Processador principal de dados"""

    def __init__(self, input_dir: str, output_dir: str):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.validator = ImageQualityValidator()

        # Estatísticas
        self.stats = {
            'total_images': 0,
            'valid_images': 0,
            'invalid_images': 0,
            'duplicates_removed': 0,
            'quality_filtered': 0,
            'class_distribution': {}
        }

        # Criar diretórios de saída
        self._create_output_directories()

    def _create_output_directories(self):
        """Cria diretórios de saída"""
        for class_name in TARGET_CLASSES:
            class_dir = self.output_dir / class_name
            class_dir.mkdir(parents=True, exist_ok=True)

        # Diretórios para relatórios
        (self.output_dir / "reports").mkdir(parents=True, exist_ok=True)
        (self.output_dir / "processed_metadata").mkdir(parents=True, exist_ok=True)

    def load_metadata(self, class_name: str) -> Optional[Dict]:
        """Carrega metadados de uma classe"""
        metadata_file = self.input_dir / \
            "metadata" / f"{class_name}_metadata.json"

        if not metadata_file.exists():
            logger.warning(f"Metadados não encontrados para {class_name}")
            return None

        try:
            with open(metadata_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Erro ao carregar metadados de {class_name}: {e}")
            return None

    def remove_duplicates(self, image_paths: List[Path]) -> List[Path]:
        """Remove imagens duplicadas baseado em hash"""
        seen_hashes = set()
        unique_images = []

        for image_path in image_paths:
            try:
                with open(image_path, 'rb') as f:
                    image_hash = hashlib.md5(f.read()).hexdigest()

                if image_hash not in seen_hashes:
                    seen_hashes.add(image_hash)
                    unique_images.append(image_path)
                else:
                    self.stats['duplicates_removed'] += 1

            except Exception as e:
                logger.warning(f"Erro ao calcular hash de {image_path}: {e}")

        return unique_images

    def process_class(self, class_name: str, max_images: int = 400) -> Dict:
        """Processa dados de uma classe específica"""
        logger.info(f"Processando classe: {class_name}")

        # Carregar metadados
        metadata = self.load_metadata(class_name)
        if not metadata:
            return {'class': class_name, 'processed': 0, 'errors': ['Metadados não encontrados']}

        # Coletar todas as imagens da classe
        raw_dir = self.input_dir / "raw_data" / class_name
        if not raw_dir.exists():
            logger.warning(f"Diretório raw não encontrado: {raw_dir}")
            return {'class': class_name, 'processed': 0, 'errors': ['Diretório raw não encontrado']}

        image_paths = list(raw_dir.glob('*.jpg')) + \
            list(raw_dir.glob('*.jpeg')) + list(raw_dir.glob('*.png'))

        if not image_paths:
            logger.warning(f"Nenhuma imagem encontrada para {class_name}")
            return {'class': class_name, 'processed': 0, 'errors': ['Nenhuma imagem encontrada']}

        logger.info(
            f"Encontradas {len(image_paths)} imagens para {class_name}")

        # Remover duplicatas
        unique_images = self.remove_duplicates(image_paths)
        logger.info(
            f"Após remoção de duplicatas: {len(unique_images)} imagens")

        # Validar qualidade
        valid_images = []
        quality_scores = []

        for image_path in unique_images:
            validation_result = self.validator.validate_image(image_path)

            if validation_result['valid']:
                valid_images.append(image_path)
                quality_scores.append(validation_result['quality_score'])
            else:
                self.stats['quality_filtered'] += 1
                logger.debug(
                    f"Imagem rejeitada {image_path}: {validation_result['issues']}")

        logger.info(
            f"Após validação de qualidade: {len(valid_images)} imagens")

        # Ordenar por qualidade e selecionar as melhores
        if len(valid_images) > max_images:
            # Criar lista de (path, score) e ordenar por score
            image_scores = list(zip(valid_images, quality_scores))
            image_scores.sort(key=lambda x: x[1], reverse=True)

            # Selecionar as melhores
            selected_images = [path for path,
                               score in image_scores[:max_images]]
            logger.info(f"Selecionadas as {max_images} melhores imagens")
        else:
            selected_images = valid_images

        # Copiar imagens para diretório final
        output_class_dir = self.output_dir / class_name
        processed_count = 0

        for i, image_path in enumerate(selected_images):
            try:
                # Gerar nome sequencial
                new_name = f"imagem{i+1:03d}.jpg"
                output_path = output_class_dir / new_name

                # Copiar e converter para JPG se necessário
                with Image.open(image_path) as img:
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                    img.save(output_path, 'JPEG', quality=95)

                processed_count += 1

            except Exception as e:
                logger.error(f"Erro ao processar {image_path}: {e}")

        # Atualizar estatísticas
        self.stats['total_images'] += len(image_paths)
        self.stats['valid_images'] += processed_count
        self.stats['invalid_images'] += len(image_paths) - processed_count
        self.stats['class_distribution'][class_name] = processed_count

        logger.info(f"Processadas {processed_count} imagens para {class_name}")

        return {
            'class': class_name,
            'processed': processed_count,
            'total_found': len(image_paths),
            'duplicates_removed': len(image_paths) - len(unique_images),
            'quality_filtered': len(unique_images) - len(valid_images),
            'final_selected': len(selected_images)
        }

    def process_all_classes(self, max_images_per_class: int = 400):
        """Processa todas as classes"""
        logger.info("Iniciando processamento de todas as classes...")

        results = {}

        for class_name in TARGET_CLASSES:
            try:
                result = self.process_class(class_name, max_images_per_class)
                results[class_name] = result

            except Exception as e:
                logger.error(f"Erro ao processar {class_name}: {e}")
                results[class_name] = {
                    'class': class_name,
                    'processed': 0,
                    'errors': [str(e)]
                }

        # Salvar relatório de processamento
        self.save_processing_report(results)

        # Gerar visualizações
        self.generate_visualizations(results)

        logger.info("Processamento concluído!")
        self.print_stats()

    def save_processing_report(self, results: Dict):
        """Salva relatório de processamento"""
        report_file = self.output_dir / "reports" / "processing_report.json"

        report_data = {
            'processing_date': datetime.now().isoformat(),
            'input_directory': str(self.input_dir),
            'output_directory': str(self.output_dir),
            'statistics': self.stats,
            'class_results': results,
            'summary': {
                'total_classes': len(TARGET_CLASSES),
                'successful_classes': sum(1 for r in results.values() if r['processed'] > 0),
                'total_images_processed': sum(r['processed'] for r in results.values()),
                'total_images_found': sum(r.get('total_found', 0) for r in results.values()),
                'total_duplicates_removed': sum(r.get('duplicates_removed', 0) for r in results.values()),
                'total_quality_filtered': sum(r.get('quality_filtered', 0) for r in results.values())
            }
        }

        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)

        logger.info(f"Relatório salvo em: {report_file}")

    def generate_visualizations(self, results: Dict):
        """Gera visualizações dos dados processados"""
        try:
            # Gráfico de distribuição por classe
            plt.figure(figsize=(15, 8))

            classes = list(results.keys())
            processed_counts = [results[cls]['processed'] for cls in classes]

            plt.subplot(2, 2, 1)
            plt.bar(range(len(classes)), processed_counts)
            plt.title('Imagens Processadas por Classe')
            plt.xlabel('Classes')
            plt.ylabel('Número de Imagens')
            plt.xticks(range(len(classes)), classes, rotation=45, ha='right')

            # Gráfico de pizza
            plt.subplot(2, 2, 2)
            plt.pie(processed_counts, labels=classes, autopct='%1.1f%%')
            plt.title('Distribuição de Imagens por Classe')

            # Estatísticas de qualidade
            plt.subplot(2, 2, 3)
            quality_stats = [results[cls].get(
                'quality_filtered', 0) for cls in classes]
            plt.bar(range(len(classes)), quality_stats, color='red', alpha=0.7)
            plt.title('Imagens Filtradas por Qualidade')
            plt.xlabel('Classes')
            plt.ylabel('Imagens Rejeitadas')
            plt.xticks(range(len(classes)), classes, rotation=45, ha='right')

            # Duplicatas removidas
            plt.subplot(2, 2, 4)
            duplicate_stats = [results[cls].get(
                'duplicates_removed', 0) for cls in classes]
            plt.bar(range(len(classes)), duplicate_stats,
                    color='orange', alpha=0.7)
            plt.title('Duplicatas Removidas')
            plt.xlabel('Classes')
            plt.ylabel('Duplicatas Removidas')
            plt.xticks(range(len(classes)), classes, rotation=45, ha='right')

            plt.tight_layout()

            # Salvar gráfico
            plot_file = self.output_dir / "reports" / "processing_visualization.png"
            plt.savefig(plot_file, dpi=300, bbox_inches='tight')
            plt.close()

            logger.info(f"Visualizações salvas em: {plot_file}")

        except Exception as e:
            logger.error(f"Erro ao gerar visualizações: {e}")

    def print_stats(self):
        """Imprime estatísticas do processamento"""
        print("\n" + "="*60)
        print("ESTATÍSTICAS DO PROCESSAMENTO")
        print("="*60)
        print(f"Total de imagens encontradas: {self.stats['total_images']}")
        print(f"Imagens válidas processadas: {self.stats['valid_images']}")
        print(f"Imagens inválidas: {self.stats['invalid_images']}")
        print(f"Duplicatas removidas: {self.stats['duplicates_removed']}")
        print(f"Filtradas por qualidade: {self.stats['quality_filtered']}")
        print("\nDistribuição por classe:")
        for class_name, count in self.stats['class_distribution'].items():
            print(f"  {class_name}: {count} imagens")
        print("="*60)


def main():
    parser = argparse.ArgumentParser(
        description='Processador de dados do iNaturalist')
    parser.add_argument('--input-dir', default='enhanced_insect_data',
                        help='Diretório de entrada com dados coletados')
    parser.add_argument('--output-dir', default='enhanced_insect_data/processed_dataset',
                        help='Diretório de saída para dados processados')
    parser.add_argument('--class', dest='target_class',
                        help='Classe específica para processar (opcional)')
    parser.add_argument('--max-images', type=int, default=400,
                        help='Máximo de imagens por classe')
    parser.add_argument('--min-size', type=int, nargs=2, default=[100, 100],
                        help='Tamanho mínimo das imagens (largura altura)')

    args = parser.parse_args()

    # Criar processador
    processor = DataProcessor(args.input_dir, args.output_dir)

    # Configurar validador
    processor.validator.min_size = tuple(args.min_size)

    if args.target_class:
        if args.target_class not in TARGET_CLASSES:
            print(f"Classe inválida: {args.target_class}")
            print(f"Classes disponíveis: {', '.join(TARGET_CLASSES)}")
            return

        # Processar uma classe específica
        result = processor.process_class(args.target_class, args.max_images)
        print(f"Resultado para {args.target_class}: {result}")
        processor.print_stats()
    else:
        # Processar todas as classes
        processor.process_all_classes(args.max_images)


if __name__ == '__main__':
    main()
