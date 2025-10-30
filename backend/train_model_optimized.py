import json
import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from PIL import Image
import matplotlib.pyplot as plt
from collections import Counter

# Definir o diretório base do projeto (raiz do projeto)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Configurações do modelo otimizadas
IMG_SIZE = 224
BATCH_SIZE = 16  # Reduzido para melhor estabilidade
EPOCHS = 100     # Aumentado para mais treinamento
LEARNING_RATE = 0.0001  # Reduzido para treinamento mais estável

# Escolher qual dataset usar
DATASET_TYPE = 'enhanced_dataset_full'

# Definir as classes (pastas)
categories = [
    'aranhas', 'besouro_carabideo', 'crisopideo', 'joaninhas', 'libelulas',
    'mosca_asilidea', 'mosca_dolicopodidea', 'mosca_sirfidea', 'mosca_taquinidea',
    'percevejo_geocoris', 'percevejo_orius', 'percevejo_pentatomideo', 'percevejo_reduviideo',
    'tesourinha', 'vespa_parasitoide', 'vespa_predadora'
]


def load_dataset_from_folders():
    """
    Carrega o dataset a partir da estrutura de pastas do enhanced_insect_data
    """
    dataset_path = os.path.join(BASE_DIR, 'enhanced_insect_data', DATASET_TYPE)

    image_paths = []
    labels = []

    print(f"Carregando dataset de: {dataset_path}")

    for category in categories:
        category_path = os.path.join(dataset_path, category)

        if not os.path.exists(category_path):
            print(f"Aviso: Pasta {category_path} não encontrada, pulando...")
            continue

        # Listar todas as imagens na pasta da categoria
        image_files = [f for f in os.listdir(category_path)
                       if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

        print(f"Categoria {category}: {len(image_files)} imagens")

        for image_file in image_files:
            image_path = os.path.join(category_path, image_file)
            image_paths.append(image_path)
            labels.append(category)

    return image_paths, labels


def create_dataframe(image_paths, labels):
    """
    Cria DataFrame e aplica balanceamento se necessário
    """
    df = pd.DataFrame({'filename': image_paths, 'class': labels})

    print("\n=== ESTATÍSTICAS DO DATASET ===")
    print("Contagem por classe:")
    class_counts = df['class'].value_counts()
    print(class_counts)

    print(f"\nTotal de imagens: {len(df)}")
    print(f"Número de classes: {len(df['class'].unique())}")

    # Verificar balanceamento
    min_samples = class_counts.min()
    max_samples = class_counts.max()
    imbalance_ratio = max_samples / min_samples

    print(f"\nBalanceamento:")
    print(f"Menor classe: {min_samples} imagens")
    print(f"Maior classe: {max_samples} imagens")
    print(f"Razão de desbalanceamento: {imbalance_ratio:.2f}")

    if imbalance_ratio > 2.0:
        print("⚠️  Dataset desbalanceado detectado!")
        print("Aplicando técnicas de balanceamento...")

        # Balanceamento por oversampling da classe menor
        target_samples = int(min_samples * 1.2)  # 20% mais que a menor classe

        balanced_dfs = []
        for class_name in df['class'].unique():
            class_df = df[df['class'] == class_name]
            if len(class_df) < target_samples:
                # Oversampling
                oversampled = class_df.sample(
                    n=target_samples, replace=True, random_state=42)
                balanced_dfs.append(oversampled)
            else:
                # Undersampling
                undersampled = class_df.sample(
                    n=target_samples, random_state=42)
                balanced_dfs.append(undersampled)

        df = pd.concat(balanced_dfs, ignore_index=True)
        print(f"Dataset balanceado: {len(df)} imagens")
        print("Nova contagem por classe:")
        print(df['class'].value_counts())

    return df


def create_data_generators(df):
    """
    Cria os geradores de dados com augmentation otimizado
    """
    # Dividir os dados
    train_df, test_df = train_test_split(
        df,
        test_size=0.2,
        random_state=42,
        stratify=df['class']
    )

    # Dividir treino em treino e validação
    train_df, val_df = train_test_split(
        train_df,
        test_size=0.2,
        random_state=42,
        stratify=train_df['class']
    )

    print(f"\nDivisão dos dados:")
    print(f"Treino: {len(train_df)} imagens")
    print(f"Validação: {len(val_df)} imagens")
    print(f"Teste: {len(test_df)} imagens")

    # Data augmentation para treino
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=30,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        brightness_range=[0.8, 1.2],
        fill_mode='nearest'
    )

    # Sem augmentation para validação e teste
    val_test_datagen = ImageDataGenerator(rescale=1./255)

    # Criar geradores
    train_generator = train_datagen.flow_from_dataframe(
        dataframe=train_df,
        x_col='filename',
        y_col='class',
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        shuffle=True
    )

    validation_generator = val_test_datagen.flow_from_dataframe(
        dataframe=val_df,
        x_col='filename',
        y_col='class',
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        shuffle=False
    )

    test_generator = val_test_datagen.flow_from_dataframe(
        dataframe=test_df,
        x_col='filename',
        y_col='class',
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        shuffle=False
    )

    return train_generator, validation_generator, test_generator


def create_model(num_classes):
    """
    Cria modelo otimizado com MobileNetV2 e fine-tuning
    """
    # Base model
    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(IMG_SIZE, IMG_SIZE, 3)
    )

    # Freeze base model layers inicialmente
    base_model.trainable = False

    # Add custom layers otimizadas
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(1024, activation='relu')(x)
    x = Dropout(0.5)(x)
    x = BatchNormalization()(x)
    x = Dense(512, activation='relu')(x)
    x = Dropout(0.3)(x)
    x = BatchNormalization()(x)
    x = Dense(256, activation='relu')(x)
    x = Dropout(0.2)(x)
    predictions = Dense(num_classes, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    # Compilar modelo
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    return model, base_model


def train_model_with_fine_tuning(model, base_model, train_generator, validation_generator):
    """
    Treina o modelo com fine-tuning em duas fases
    """
    # Callbacks otimizados
    callbacks = [
        EarlyStopping(
            monitor='val_accuracy',
            patience=15,  # Aumentado
            restore_best_weights=True,
            verbose=1
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.3,   # Redução mais agressiva
            patience=7,   # Reduzido
            min_lr=1e-8,
            verbose=1
        )
    ]

    # Fase 1: Treinar apenas as camadas customizadas
    print("\n=== FASE 1: TREINAMENTO DAS CAMADAS CUSTOMIZADAS ===")
    history1 = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // train_generator.batch_size,
        validation_data=validation_generator,
        validation_steps=validation_generator.samples // validation_generator.batch_size,
        epochs=30,  # Primeira fase
        callbacks=callbacks,
        verbose=1
    )

    # Fase 2: Fine-tuning com learning rate menor
    print("\n=== FASE 2: FINE-TUNING DO MODELO BASE ===")

    # Descongelar algumas camadas do modelo base
    base_model.trainable = True

    # Descongelar apenas as últimas camadas
    for layer in base_model.layers[:-30]:  # Manter mais camadas congeladas
        layer.trainable = False

    # Recompilar com learning rate menor
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE/10),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    # Continuar treinamento
    history2 = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // train_generator.batch_size,
        validation_data=validation_generator,
        validation_steps=validation_generator.samples // validation_generator.batch_size,
        epochs=EPOCHS,
        callbacks=callbacks,
        verbose=1,
        initial_epoch=len(history1.history['loss'])
    )

    # Combinar históricos
    combined_history = {
        'loss': history1.history['loss'] + history2.history['loss'],
        'accuracy': history1.history['accuracy'] + history2.history['accuracy'],
        'val_loss': history1.history['val_loss'] + history2.history['val_loss'],
        'val_accuracy': history1.history['val_accuracy'] + history2.history['val_accuracy']
    }

    return combined_history


def evaluate_model(model, test_generator):
    """
    Avalia o modelo no conjunto de teste
    """
    print("\n=== AVALIAÇÃO DO MODELO ===")

    # Avaliar modelo
    test_loss, test_accuracy = model.evaluate(
        test_generator,
        steps=test_generator.samples // test_generator.batch_size,
        verbose=1
    )

    print(f"Acurácia no conjunto de teste: {test_accuracy:.4f}")
    print(f"Perda no conjunto de teste: {test_loss:.4f}")

    return test_loss, test_accuracy


def plot_training_history(history):
    """
    Plota o histórico de treinamento
    """
    plt.figure(figsize=(15, 5))

    # Acurácia
    plt.subplot(1, 3, 1)
    plt.plot(history['accuracy'], label='Treino')
    plt.plot(history['val_accuracy'], label='Validação')
    plt.title('Acurácia do Modelo')
    plt.xlabel('Época')
    plt.ylabel('Acurácia')
    plt.legend()
    plt.grid(True)

    # Perda
    plt.subplot(1, 3, 2)
    plt.plot(history['loss'], label='Treino')
    plt.plot(history['val_loss'], label='Validação')
    plt.title('Perda do Modelo')
    plt.xlabel('Época')
    plt.ylabel('Perda')
    plt.legend()
    plt.grid(True)

    # Learning Rate (se disponível)
    plt.subplot(1, 3, 3)
    if 'lr' in history:
        plt.plot(history['lr'], label='Learning Rate')
        plt.title('Taxa de Aprendizado')
        plt.xlabel('Época')
        plt.ylabel('Learning Rate')
        plt.yscale('log')
    else:
        plt.text(0.5, 0.5, 'Learning Rate\nnão disponível',
                 ha='center', va='center', transform=plt.gca().transAxes)
        plt.title('Taxa de Aprendizado')
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.savefig(os.path.join(BASE_DIR, 'backend',
                'training_history_optimized.png'), dpi=300, bbox_inches='tight')
    print("Gráfico do histórico de treinamento salvo em: training_history_optimized.png")


def save_model_info(model, test_accuracy, num_classes, total_images):
    """
    Salva informações do modelo
    """
    model_info = {
        'dataset_type': DATASET_TYPE,
        'total_images': total_images,
        'num_classes': num_classes,
        'test_accuracy': float(test_accuracy),
        'img_size': IMG_SIZE,
        'batch_size': BATCH_SIZE,
        'epochs': EPOCHS,
        'learning_rate': LEARNING_RATE,
        'model_architecture': 'MobileNetV2 + Custom Dense Layers + Fine-tuning',
        'categories': categories,
        'optimization_features': [
            'MobileNetV2 base model',
            'Batch normalization layers',
            'Two-phase training (frozen + fine-tuning)',
            'Data augmentation',
            'Dataset balancing',
            'Reduced learning rate for fine-tuning'
        ]
    }

    info_path = os.path.join(
        BASE_DIR, 'backend', 'models', 'model_info_optimized.json')
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, indent=2, ensure_ascii=False)

    print(f"Informações do modelo salvas em: {info_path}")


def main():
    """
    Função principal
    """
    print("=== TREINAMENTO DO MODELO OTIMIZADO ===")
    print(f"Dataset: {DATASET_TYPE}")
    print(f"Tamanho da imagem: {IMG_SIZE}x{IMG_SIZE}")
    print(f"Batch size: {BATCH_SIZE}")
    print(f"Épocas máximas: {EPOCHS}")
    print(f"Learning rate: {LEARNING_RATE}")

    # Carregar dados
    image_paths, labels = load_dataset_from_folders()

    if not image_paths:
        print("❌ Nenhuma imagem encontrada! Verifique o caminho do dataset.")
        return

    # Criar DataFrame com balanceamento
    df = create_dataframe(image_paths, labels)

    # Criar geradores
    train_generator, validation_generator, test_generator = create_data_generators(
        df)

    # Criar modelo
    num_classes = len(categories)
    model, base_model = create_model(num_classes)

    print(f"\n=== ARQUITETURA DO MODELO ===")
    model.summary()

    # Treinar modelo com fine-tuning
    print(f"\n=== INICIANDO TREINAMENTO COM FINE-TUNING ===")
    history = train_model_with_fine_tuning(
        model, base_model, train_generator, validation_generator)

    # Avaliar modelo
    test_loss, test_accuracy = evaluate_model(model, test_generator)

    # Salvar modelo final
    final_model_path = os.path.join(
        BASE_DIR, 'backend', 'models', 'insect_classifier_optimized.h5')

    try:
        model.save(final_model_path)
        print(f"\nModelo final salvo em: {final_model_path}")
    except Exception as e:
        print(f"Erro ao salvar modelo: {e}")
        # Salvar apenas os pesos
        weights_path = os.path.join(
            BASE_DIR, 'backend', 'models', 'insect_classifier_optimized_weights.h5')
        model.save_weights(weights_path)
        print(f"Pesos do modelo salvos em: {weights_path}")

    # Converter para TensorFlow Lite
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()

        tflite_path = os.path.join(
            BASE_DIR, 'backend', 'models', 'insect_classifier_optimized.tflite')
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        print(f"Modelo TensorFlow Lite salvo em: {tflite_path}")
    except Exception as e:
        print(f"Erro ao converter para TensorFlow Lite: {e}")

    # Plotar histórico
    plot_training_history(history)

    # Salvar informações
    save_model_info(model, test_accuracy, num_classes, len(df))

    print(f"\n=== TREINAMENTO CONCLUÍDO ===")
    print(f"Acurácia final: {test_accuracy:.4f}")

    if test_accuracy >= 0.75:
        print("🎉 Meta de acurácia atingida!")
    else:
        print("⚠️  Meta de acurácia não atingida. Considere:")
        print("   - Mais épocas de treinamento")
        print("   - Diferentes arquiteturas")
        print("   - Mais dados de treinamento")


if __name__ == "__main__":
    main()
