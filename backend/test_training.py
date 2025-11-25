#!/usr/bin/env python3
"""
Teste Simples do Sistema de Treinamento
Verifica se os dados estão organizados corretamente
"""

import os
import sys
from pathlib import Path


def test_dataset_structure():
    """Testa a estrutura do dataset"""
    print("Testando estrutura do dataset...")

    # Caminho do dataset
    dataset_path = Path("../enhanced_insect_data/enhanced_dataset")

    if not dataset_path.exists():
        print(f"Dataset não encontrado em: {dataset_path}")
        return False

    print(f"Dataset encontrado em: {dataset_path}")

    # Verificar classes
    classes = [d.name for d in dataset_path.iterdir() if d.is_dir()]
    print(f"Classes encontradas: {len(classes)}")

    total_images = 0
    for class_name in classes:
        class_path = dataset_path / class_name
        images = list(class_path.glob("*.jpg")) + \
            list(class_path.glob("*.png"))
        print(f"   {class_name}: {len(images)} imagens")
        total_images += len(images)

    print(f"Total de imagens: {total_images}")

    # Verificar se há dados suficientes
    if total_images < 100:
        print("Poucas imagens para treinamento eficaz")
        return False

    print("Dataset pronto para treinamento!")
    return True


def test_model_directory():
    """Testa o diretório de modelos"""
    print("\nTestando diretório de modelos...")

    models_path = Path("models")

    if not models_path.exists():
        print("Criando diretório de modelos...")
        models_path.mkdir(exist_ok=True)

    print(f"Diretório de modelos: {models_path}")

    # Verificar modelos existentes
    model_files = list(models_path.glob("*.tflite")) + \
        list(models_path.glob("*.h5"))

    if model_files:
        print("Modelos existentes:")
        for model_file in model_files:
            size_mb = model_file.stat().st_size / (1024 * 1024)
            print(f"   {model_file.name}: {size_mb:.1f} MB")
    else:
        print("Nenhum modelo encontrado - pronto para treinamento")

    return True


def test_dependencies():
    """Testa dependências básicas"""
    print("\nTestando dependências...")

    try:
        import numpy as np
        print("NumPy disponível")
    except ImportError:
        print("NumPy não encontrado")
        return False

    try:
        import PIL
        print("PIL/Pillow disponível")
    except ImportError:
        print("PIL/Pillow não encontrado")
        return False

    try:
        import cv2
        print("OpenCV disponível")
    except ImportError:
        print("OpenCV não encontrado")
        return False

    try:
        import tensorflow as tf
        print(f"TensorFlow disponível: {tf.__version__}")
    except ImportError:
        print("TensorFlow não encontrado")
        print("Execute: pip install tensorflow==2.15.0")
        return False

    return True


def main():
    """Função principal de teste"""
    print("Teste do Sistema de Treinamento")
    print("=" * 40)

    # Testar estrutura do dataset
    dataset_ok = test_dataset_structure()

    # Testar diretório de modelos
    models_ok = test_model_directory()

    # Testar dependências
    deps_ok = test_dependencies()

    print("\nResumo dos Testes:")
    print(f"   Dataset: {'OK' if dataset_ok else 'ERRO'}")
    print(f"   Modelos: {'OK' if models_ok else 'ERRO'}")
    print(f"   Dependências: {'OK' if deps_ok else 'ERRO'}")

    if dataset_ok and models_ok and deps_ok:
        print("\nSistema pronto para treinamento!")
        print("\nPróximos passos:")
        print("   1. Execute: python train_model.py --data-dir ../enhanced_insect_data/enhanced_dataset")
        print("   2. Aguarde o treinamento (pode demorar algumas horas)")
        print("   3. Use o modelo treinado na API")
        return True
    else:
        print("\nCorrija os problemas antes de treinar")
        return False


if __name__ == '__main__':
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\nTeste interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\nErro inesperado: {e}")
        sys.exit(1)
