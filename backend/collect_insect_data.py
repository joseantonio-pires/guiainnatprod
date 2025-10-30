#!/usr/bin/env python3
"""
Script Principal de Coleta de Dados de Insetos do iNaturalist
Integra coleta, processamento e backup de dados para treinamento de modelos de IA
"""

from data_processor import DataProcessor
from inaturalist_collector import iNaturalistCollector
import os
import sys
import argparse
import logging
from pathlib import Path
from datetime import datetime
import json

# Configurar logging primeiro
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('collect_insect_data.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Importar módulos do sistema

# BackupManager opcional (pode não existir)
try:
    from data_backup_manager import BackupManager
    BACKUP_AVAILABLE = True
except ImportError:
    BACKUP_AVAILABLE = False
    logger.warning(
        "BackupManager não disponível - funcionalidade de backup desabilitada")

# Configurar UTF-8 no Windows
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass


class InsectDataPipeline:
    """Pipeline completo de coleta e processamento de dados de insetos"""

    def __init__(self, base_dir: str = "enhanced_insect_data"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

        # Inicializar componentes
        self.collector = iNaturalistCollector(str(self.base_dir))
        self.processor = DataProcessor(
            str(self.base_dir), str(self.base_dir / "processed_dataset"))

        # BackupManager opcional
        if BACKUP_AVAILABLE:
            self.backup_manager = BackupManager(str(self.base_dir))
        else:
            self.backup_manager = None

        # Configurações padrão
        self.config = {
            'max_observations_per_class': 1000,
            'max_images_per_class': 400,
            'create_backup': True,
            'process_data': True,
            'quality_threshold': 0.5
        }

    def run_full_pipeline(self, class_name: str = None,
                          max_observations: int = 1000,
                          max_images: int = 400,
                          create_backup: bool = True) -> bool:
        """Executa pipeline completo de coleta e processamento"""
        try:
            logger.info("Iniciando pipeline completo de coleta de dados...")

            # Fase 1: Coleta de dados
            logger.info("Fase 1: Coleta de dados do iNaturalist")
            if class_name:
                data = self.collector.collect_data_for_class(
                    class_name, max_observations)
                self.collector.save_metadata(class_name, data)
            else:
                self.collector.collect_all_data(max_observations)

            # Fase 2: Processamento de dados
            if self.config['process_data']:
                logger.info("🔧 Fase 2: Processamento e validação de dados")
                if class_name:
                    result = self.processor.process_class(
                        class_name, max_images)
                    logger.info(f"Processamento de {class_name}: {result}")
                else:
                    self.processor.process_all_classes(max_images)

            # Fase 3: Backup
            if create_backup and self.backup_manager:
                logger.info("Fase 3: Criação de backup")
                backup_id = self.backup_manager.create_backup(
                    f"Pipeline completo - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
                )
                if backup_id:
                    logger.info(f"Backup criado: {backup_id}")
                else:
                    logger.warning("Falha ao criar backup")
            elif create_backup and not self.backup_manager:
                logger.warning(
                    "Backup solicitado mas BackupManager não disponível")

            logger.info("[OK] Pipeline concluído com sucesso!")
            return True

        except Exception as e:
            logger.error(f"[ERRO] Erro no pipeline: {e}")
            return False

    def collect_only(self, class_name: str = None, max_observations: int = 1000) -> bool:
        """Executa apenas a coleta de dados"""
        try:
            logger.info("Iniciando coleta de dados...")

            if class_name:
                data = self.collector.collect_data_for_class(
                    class_name, max_observations)
                self.collector.save_metadata(class_name, data)
            else:
                self.collector.collect_all_data(max_observations)

            self.collector.print_stats()
            return True

        except Exception as e:
            logger.error(f"[ERRO] Erro na coleta: {e}")
            return False

    def process_only(self, class_name: str = None, max_images: int = 400) -> bool:
        """Executa apenas o processamento de dados"""
        try:
            logger.info("🔧 Iniciando processamento de dados...")

            if class_name:
                result = self.processor.process_class(class_name, max_images)
                logger.info(f"Resultado: {result}")
            else:
                self.processor.process_all_classes(max_images)

            self.processor.print_stats()
            return True

        except Exception as e:
            logger.error(f"[ERRO] Erro no processamento: {e}")
            return False

    def backup_only(self, description: str = None) -> bool:
        """Executa apenas o backup"""
        try:
            logger.info("[BACKUP] Iniciando backup...")

            backup_id = self.backup_manager.create_backup(
                description or f"Backup manual - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
            )

            if backup_id:
                logger.info(f"[OK] Backup criado: {backup_id}")
                return True
            else:
                logger.error("[ERRO] Falha ao criar backup")
                return False

        except Exception as e:
            logger.error(f"[ERRO] Erro no backup: {e}")
            return False

    def restore_backup(self, version_id: str, target_dir: str = None) -> bool:
        """Restaura um backup específico"""
        try:
            logger.info(f"🔄 Restaurando backup {version_id}...")

            success = self.backup_manager.restore_backup(
                version_id, target_dir)

            if success:
                logger.info(f"[OK] Backup {version_id} restaurado com sucesso")
                return True
            else:
                logger.error(f"[ERRO] Falha ao restaurar backup {version_id}")
                return False

        except Exception as e:
            logger.error(f"[ERRO] Erro na restauração: {e}")
            return False

    def list_backups(self):
        """Lista todos os backups disponíveis"""
        try:
            versions = self.backup_manager.list_versions()

            if versions:
                print("\n[LISTA] Backups disponíveis:")
                print("-" * 80)
                for version in versions:
                    status = "✓" if self.backup_manager.verify_backup(
                        version.version_id) else "✗"
                    print(f"{status} {version.version_id}")
                    print(f"   Data: {version.timestamp}")
                    print(f"   Descrição: {version.description}")
                    print(f"   Tamanho: {version.data_size:,} bytes")
                    print(f"   Arquivos: {version.file_count}")
                    print("-" * 80)
            else:
                print("[LISTA] Nenhum backup encontrado.")

        except Exception as e:
            logger.error(f"[ERRO] Erro ao listar backups: {e}")

    def get_status(self):
        """Obtém status geral do sistema"""
        try:
            print("\n" + "="*60)
            print("STATUS DO SISTEMA DE COLETA DE DADOS")
            print("="*60)

            # Status dos dados
            raw_dir = self.base_dir / "raw_data"
            processed_dir = self.base_dir / "processed_dataset"

            print(f"📁 Diretório base: {self.base_dir}")
            print(
                f" Dados brutos: {'✓' if raw_dir.exists() else '✗'} {raw_dir}")
            print(
                f"🔧 Dados processados: {'✓' if processed_dir.exists() else '✗'} {processed_dir}")

            # Contar imagens por classe
            if raw_dir.exists():
                print(f"\n📊 Dados brutos por classe:")
                for class_dir in raw_dir.iterdir():
                    if class_dir.is_dir():
                        image_count = len(
                            list(class_dir.glob('*.jpg'))) + len(list(class_dir.glob('*.jpeg')))
                        print(f"   {class_dir.name}: {image_count} imagens")

            if processed_dir.exists():
                print(f"\n📊 Dados processados por classe:")
                for class_dir in processed_dir.iterdir():
                    if class_dir.is_dir():
                        image_count = len(list(class_dir.glob('*.jpg')))
                        print(f"   {class_dir.name}: {image_count} imagens")

            # Status dos backups
            stats = self.backup_manager.get_statistics()
            print(f"\n[BACKUP] Backups:")
            print(f"   Total de versões: {stats['total_versions']}")
            print(f"   Tamanho total: {stats['total_data_size']:,} bytes")
            print(f"   Total de arquivos: {stats['total_files']}")

            print("="*60)

        except Exception as e:
            logger.error(f"[ERRO] Erro ao obter status: {e}")


def main():
    parser = argparse.ArgumentParser(
        description='Sistema de Coleta de Dados de Insetos do iNaturalist',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:

1. Coleta completa de todas as classes:
   python collect_insect_data.py --action full

2. Coleta apenas de uma classe específica:
   python collect_insect_data.py --action full --class aranhas

3. Apenas coletar dados (sem processar):
   python collect_insect_data.py --action collect

4. Apenas processar dados existentes:
   python collect_insect_data.py --action process

5. Criar backup:
   python collect_insect_data.py --action backup

6. Listar backups:
   python collect_insect_data.py --action list-backups

7. Restaurar backup:
   python collect_insect_data.py --action restore --version-id v20231201_143022

8. Ver status do sistema:
   python collect_insect_data.py --action status
        """
    )

    parser.add_argument('--action',
                        choices=['full', 'collect', 'process', 'backup',
                                 'restore', 'list-backups', 'status'],
                        required=True,
                        help='Ação a executar')
    parser.add_argument('--data-dir', default='enhanced_insect_data',
                        help='Diretório de dados (padrão: enhanced_insect_data)')
    parser.add_argument('--class-name', dest='class_name',
                        help='Classe específica para processar (opcional)')
    parser.add_argument('--max-observations', type=int, default=1000,
                        help='Máximo de observações por classe (padrão: 1000)')
    parser.add_argument('--max-images', type=int, default=400,
                        help='Máximo de imagens por classe no processamento (padrão: 400)')
    parser.add_argument('--version-id',
                        help='ID da versão para restaurar')
    parser.add_argument('--target-dir',
                        help='Diretório de destino para restauração')
    parser.add_argument('--description',
                        help='Descrição para backup')
    parser.add_argument('--no-backup', action='store_true',
                        help='Não criar backup automático')
    parser.add_argument('--no-process', action='store_true',
                        help='Não processar dados automaticamente')

    args = parser.parse_args()

    # Criar pipeline
    pipeline = InsectDataPipeline(args.data_dir)

    # Configurar pipeline
    pipeline.config['max_observations_per_class'] = args.max_observations
    pipeline.config['max_images_per_class'] = args.max_images
    pipeline.config['create_backup'] = not args.no_backup
    pipeline.config['process_data'] = not args.no_process

    # Executar ação solicitada
    success = False

    if args.action == 'full':
        success = pipeline.run_full_pipeline(
            args.class_name,
            args.max_observations,
            args.max_images,
            pipeline.config['create_backup']
        )

    elif args.action == 'collect':
        success = pipeline.collect_only(args.class_name, args.max_observations)

    elif args.action == 'process':
        success = pipeline.process_only(args.class_name, args.max_images)

    elif args.action == 'backup':
        success = pipeline.backup_only(args.description)

    elif args.action == 'restore':
        if not args.version_id:
            print("[ERRO] --version-id é obrigatório para restore")
            return
        success = pipeline.restore_backup(args.version_id, args.target_dir)

    elif args.action == 'list-backups':
        pipeline.list_backups()
        success = True

    elif args.action == 'status':
        pipeline.get_status()
        success = True

    if success:
        print("\n[OK] Operação concluída com sucesso!")
    else:
        print("\n[ERRO] Operação falhou!")
        sys.exit(1)


if __name__ == '__main__':
    main()
