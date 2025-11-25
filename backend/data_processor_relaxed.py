#!/usr/bin/env python3
"""
Processador de Dados com Critérios Menos Restritivos
Processa todas as imagens disponíveis com validação mais flexível
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
        logging.FileHandler('data_processor_relaxed.log'),
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


class RelaxedImageValidator:
    """Validador de qualidade com critérios mais flexíveis"""

    def __init__(self, min_size: Tuple[int, int] = (50, 50),  # Reduzido de 100x100
                 max_blur_threshold: float = 50.0,  # Reduzido de 100.0
                 min_brightness: float = 0.05,  # Reduzido de 0.1
                 max_brightness: float = 0.95):  # Aumentado de 0.9
        self.min_size = min_size
        self.max_blur_threshold = max_blur_threshold
        self.min_brightness = min_brightness
        self.max_brightness = max_brightness

    def validate_image(self, image_path: Path) -> Dict:
        """Valida a qualidade de uma imagem com critérios flexíveis"""
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

            # Verificar tamanho mínimo (mais flexível)
            if width < self.min_size[0] or height < self.min_size[1]:
                result['valid'] = False
                result['issues'].append(
                    f'Tamanho muito pequeno: {width}x{height}')

            # Verificar blur (mais flexível)
            blur_score = self._calculate_blur_score(image_rgb)
            result['blur_score'] = blur_score
            if blur_score < self.max_blur_threshold:
                result['valid'] = False
                result['issues'].append(
                    f'Imagem muito desfocada: {blur_score:.2f}')

            # Verificar brilho (mais flexível)
            brightness = self._calculate_brightness(image_rgb)
            result['brightness'] = brightness
            if brightness < self.min_brightness or brightness > self.max_brightness:
                result['valid'] = False
                result['issues'].append(
                    f'Brilho inadequado: {brightness:.2f}')

            # Calcular score de qualidade (mais generoso)
            result['quality_score'] = self._calculate_quality_score(
                width, height, blur_score, brightness)

        except Exception as e:
            result['valid'] = False
            result['issues'].append(f'Erro na validação: {str(e)}')

        return result

    def _calculate_blur_score(self, image: np.ndarray) -> float:
        """Calcula score de blur usando Laplacian"""
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
            return cv2.Laplacian(gray, cv2.CV_64F).var()
        except:
            return 0.0

    def _calculate_brightness(self, image: np.ndarray) -> float:
        """Calcula brilho médio da imagem"""
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
            return np.mean(gray) / 255.0
        except:
            return 0.5

    def _calculate_quality_score(self, width: int, height: int,
                                 blur_score: float, brightness: float) -> float:
        """Calcula score de qualidade (0-1)"""
        # Score baseado no tamanho
        size_score = min(1.0, (width * height) / (224 * 224))

        # Score baseado no blur
        blur_score_norm = min(1.0, blur_score / 200.0)

        # Score baseado no brilho (penalizar extremos)
        brightness_score = 1.0 - abs(brightness - 0.5) * 2

        # Score combinado
        return (size_score * 0.3 + blur_score_norm * 0.4 + brightness_score * 0.3)


class RelaxedDataProcessor:
    """Processador de dados com critérios flexíveis"""

    def __init__(self, input_dir: str, output_dir: str, max_images_per_class: int = 1000):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.max_images_per_class = max_images_per_class
        self.validator = RelaxedImageValidator()

        # Estatísticas
        self.stats = {
            'total_found': 0,
            'total_processed': 0,
            'total_invalid': 0,
            'duplicates_removed': 0,
            'quality_filtered': 0,
            'class_distribution': {}
        }

    def process_all_classes(self):
        """Processa todas as classes de insetos"""
        logger.info("Iniciando processamento com critérios flexíveis...")

        # Criar diretório de saída
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Processar cada classe
        for class_name in TARGET_CLASSES:
            logger.info(f"Processando classe: {class_name}")
            self._process_class(class_name)

        # Gerar relatório
        self._generate_report()

        logger.info("Processamento concluído!")

    def _process_class(self, class_name: str):
        """Processa uma classe específica"""
        class_input_dir = self.input_dir / 'raw_data' / class_name
        class_output_dir = self.output_dir / class_name

        if not class_input_dir.exists():
            logger.warning(f"Diretório não encontrado: {class_input_dir}")
            return

        # Criar diretório de saída
        class_output_dir.mkdir(parents=True, exist_ok=True)

        # Encontrar todas as imagens
        image_files = []
        for ext in ['*.jpg', '*.jpeg', '*.png']:
            image_files.extend(class_input_dir.glob(ext))

        logger.info(
            f"Encontradas {len(image_files)} imagens para {class_name}")
        self.stats['total_found'] += len(image_files)

        # Remover duplicatas
        unique_images = self._remove_duplicates(image_files)
        logger.info(
            f"Após remoção de duplicatas: {len(unique_images)} imagens")

        # Validar e processar imagens
        valid_images = []
        for image_path in unique_images:
            validation_result = self.validator.validate_image(image_path)

            if validation_result['valid']:
                valid_images.append((image_path, validation_result))
            else:
                self.stats['total_invalid'] += 1

        logger.info(
            f"Após validação de qualidade: {len(valid_images)} imagens")

        # Ordenar por qualidade e selecionar as melhores
        valid_images.sort(key=lambda x: x[1]['quality_score'], reverse=True)

        # Limitar número de imagens por classe
        selected_images = valid_images[:self.max_images_per_class]

        # Copiar imagens selecionadas
        processed_count = 0
        for image_path, validation_result in selected_images:
            try:
                output_path = class_output_dir / image_path.name
                shutil.copy2(image_path, output_path)
                processed_count += 1
            except Exception as e:
                logger.error(f"Erro ao copiar {image_path}: {e}")

        logger.info(f"Processadas {processed_count} imagens para {class_name}")
        self.stats['total_processed'] += processed_count
        self.stats['class_distribution'][class_name] = processed_count

    def _remove_duplicates(self, image_files: List[Path]) -> List[Path]:
        """Remove duplicatas baseado em hash MD5"""
        seen_hashes = set()
        unique_files = []

        for image_path in image_files:
            try:
                with open(image_path, 'rb') as f:
                    file_hash = hashlib.md5(f.read()).hexdigest()

                if file_hash not in seen_hashes:
                    seen_hashes.add(file_hash)
                    unique_files.append(image_path)
                else:
                    self.stats['duplicates_removed'] += 1
            except Exception as e:
                logger.error(f"Erro ao calcular hash de {image_path}: {e}")

        return unique_files

    def _generate_report(self):
        """Gera relatório do processamento"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'input_directory': str(self.input_dir),
            'output_directory': str(self.output_dir),
            'max_images_per_class': self.max_images_per_class,
            'statistics': self.stats,
            'validator_settings': {
                'min_size': self.validator.min_size,
                'max_blur_threshold': self.validator.max_blur_threshold,
                'min_brightness': self.validator.min_brightness,
                'max_brightness': self.validator.max_brightness
            }
        }

        # Salvar relatório
        report_dir = self.output_dir / 'reports'
        report_dir.mkdir(exist_ok=True)

        report_path = report_dir / 'processing_report.json'
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        logger.info(f"Relatório salvo em: {report_path}")

        # Imprimir estatísticas
        self._print_statistics()

    def _print_statistics(self):
        """Imprime estatísticas do processamento"""
        print("\n" + "="*60)
        print("ESTATÍSTICAS DO PROCESSAMENTO")
        print("="*60)
        print(f"Total de imagens encontradas: {self.stats['total_found']}")
        print(f"Imagens válidas processadas: {self.stats['total_processed']}")
        print(f"Imagens inválidas: {self.stats['total_invalid']}")
        print(f"Duplicatas removidas: {self.stats['duplicates_removed']}")
        print(
            f"Filtradas por qualidade: {self.stats['total_found'] - self.stats['total_processed'] - self.stats['duplicates_removed']}")

        print("\nDistribuição por classe:")
        for class_name, count in self.stats['class_distribution'].items():
            print(f"  {class_name}: {count} imagens")
        print("="*60)


def main():
    """Função principal"""
    parser = argparse.ArgumentParser(
        description='Processador de dados com critérios flexíveis')
    parser.add_argument('--input-dir', default='enhanced_insect_data',
                        help='Diretório de entrada com dados brutos')
    parser.add_argument('--output-dir', default='../enhanced_insect_data/enhanced_dataset_full',
                        help='Diretório de saída para dados processados')
    parser.add_argument('--max-images', type=int, default=1000,
                        help='Máximo de imagens por classe')

    args = parser.parse_args()

    # Criar processador
    processor = RelaxedDataProcessor(
        input_dir=args.input_dir,
        output_dir=args.output_dir,
        max_images_per_class=args.max_images
    )

    # Processar dados
    processor.process_all_classes()


if __name__ == '__main__':
    main()
