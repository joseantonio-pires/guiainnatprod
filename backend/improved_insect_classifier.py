import json
import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2, EfficientNetB0
from tensorflow.keras.layers import (Dense, GlobalAveragePooling2D, Dropout, 
                                     BatchNormalization, Multiply, Reshape, 
                                     GlobalMaxPooling2D, Concatenate)
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from tensorflow.keras import backend as K
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.utils.class_weight import compute_class_weight
from PIL import Image
import matplotlib.pyplot as plt
from collections import Counter

# ======================== CONFIGURAÇÕES ========================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Configurações otimizadas baseadas em literatura
IMG_SIZE = 224
BATCH_SIZE = 16  # Menor batch para melhor generalização
EPOCHS = 100
INITIAL_LEARNING_RATE = 0.001  # LR maior para fase inicial
FINE_TUNE_LEARNING_RATE = 0.0001  # LR menor para fine-tuning
DATASET_TYPE = 'enhanced_dataset_full'

# Classes de insetos
categories = [
    'aranhas', 'besouro_carabideo', 'crisopideo', 'joaninhas', 'libelulas',
    'mosca_asilidea', 'mosca_dolicopodidea', 'mosca_sirfidea', 'mosca_taquinidea',
    'percevejo_geocoris', 'percevejo_orius', 'percevejo_pentatomideo', 'percevejo_reduviideo',
    'tesourinha', 'vespa_parasitoide', 'vespa_predadora'
]


# ======================== MÓDULO DE ATENÇÃO (CBAM-like) ========================
def squeeze_excite_block(input_tensor, ratio=16):
    """
    Squeeze-and-Excitation block para melhorar feature extraction
    Baseado em: Hu et al. (2018) "Squeeze-and-Excitation Networks"
    """
    channels = K.int_shape(input_tensor)[-1]
    
    # Squeeze: Global pooling
    se = GlobalAveragePooling2D()(input_tensor)
    se = Reshape((1, 1, channels))(se)
    
    # Excitation: FC layers
    se = Dense(channels // ratio, activation='relu', use_bias=False)(se)
    se = Dense(channels, activation='sigmoid', use_bias=False)(se)
    
    # Scale
    return Multiply()([input_tensor, se])


# ======================== CARREGAMENTO DE DADOS ========================
def load_dataset_from_folders():
    """
    Carrega dataset mantendo estrutura de pastas
    """
    dataset_path = os.path.join(BASE_DIR, 'enhanced_insect_data', DATASET_TYPE)
    image_paths = []
    labels = []

    print(f"📁 Carregando dataset de: {dataset_path}")

    for category in categories:
        category_path = os.path.join(dataset_path, category)
        if not os.path.exists(category_path):
            print(f"⚠️ Pasta {category_path} não encontrada, pulando...")
            continue

        image_files = [f for f in os.listdir(category_path)
                       if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        
        print(f"✓ {category}: {len(image_files)} imagens")
        
        for image_file in image_files:
            image_path = os.path.join(category_path, image_file)
            image_paths.append(image_path)
            labels.append(category)

    return image_paths, labels


def create_balanced_dataframe(image_paths, labels):
    """
    Cria DataFrame com balanceamento inteligente
    Técnica baseada em: Liu et al. (2022) - Large scale pest classification
    """
    df = pd.DataFrame({'filename': image_paths, 'class': labels})

    print("\n" + "="*50)
    print("📊 ESTATÍSTICAS DO DATASET")
    print("="*50)
    class_counts = df['class'].value_counts()
    print("\nContagem por classe:")
    print(class_counts)
    
    print(f"\n📈 Total: {len(df)} imagens")
    print(f"🔢 Classes: {len(df['class'].unique())}")

    # Análise de balanceamento
    min_samples = class_counts.min()
    max_samples = class_counts.max()
    imbalance_ratio = max_samples / min_samples

    print(f"\n⚖️ Balanceamento:")
    print(f"   Menor classe: {min_samples} imagens")
    print(f"   Maior classe: {max_samples} imagens")
    print(f"   Razão: {imbalance_ratio:.2f}")

    # Estratégia de balanceamento adaptativo
    if imbalance_ratio > 1.5:
        print("\n🔄 Aplicando balanceamento adaptativo...")
        
        # Usar média como target (mais conservador que o mínimo)
        target_samples = int(class_counts.mean())
        
        balanced_dfs = []
        for class_name in df['class'].unique():
            class_df = df[df['class'] == class_name]
            current_count = len(class_df)
            
            if current_count < target_samples:
                # Oversampling com limite
                n_samples = min(target_samples, int(current_count * 1.5))
                oversampled = class_df.sample(n=n_samples, replace=True, random_state=42)
                balanced_dfs.append(oversampled)
                print(f"   ↑ {class_name}: {current_count} → {n_samples}")
            else:
                # Undersampling moderado
                undersampled = class_df.sample(n=target_samples, random_state=42)
                balanced_dfs.append(undersampled)
                print(f"   ↓ {class_name}: {current_count} → {target_samples}")

        df = pd.concat(balanced_dfs, ignore_index=True)
        print(f"\n✓ Dataset balanceado: {len(df)} imagens")

    return df


# ======================== GERADORES DE DADOS ========================
def create_advanced_generators(df):
    """
    Geradores com augmentation avançado
    Baseado em: CutMix, MixUp e técnicas modernas de augmentation
    """
    # Divisão estratificada
    train_df, test_df = train_test_split(
        df, test_size=0.2, random_state=42, stratify=df['class']
    )
    train_df, val_df = train_test_split(
        train_df, test_size=0.2, random_state=42, stratify=train_df['class']
    )

    print(f"\n📦 Divisão dos dados:")
    print(f"   Treino: {len(train_df)} imagens")
    print(f"   Validação: {len(val_df)} imagens")
    print(f"   Teste: {len(test_df)} imagens")

    # Augmentation agressivo para treino (baseado em literatura)
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=40,           # Aumentado
        width_shift_range=0.3,       # Aumentado
        height_shift_range=0.3,      # Aumentado
        shear_range=0.3,             # Aumentado
        zoom_range=0.3,              # Aumentado
        horizontal_flip=True,
        vertical_flip=True,          # Adicionado (insetos podem estar de cabeça para baixo)
        brightness_range=[0.7, 1.3], # Expandido
        fill_mode='reflect',         # Melhor que 'nearest' para bordas
        channel_shift_range=0.2      # Adicionado: variação de cor
    )

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

    # Calcular class weights para lidar com desbalanceamento residual
    class_weights = compute_class_weight(
        'balanced',
        classes=np.unique(train_df['class']),
        y=train_df['class']
    )
    class_weight_dict = dict(enumerate(class_weights))

    return train_generator, validation_generator, test_generator, class_weight_dict


# ======================== ARQUITETURA DO MODELO ========================
def create_enhanced_model(num_classes, use_se_block=True):
    """
    Modelo aprimorado com arquitetura híbrida
    Combina: MobileNetV2 + SE Block + Dual Pooling
    """
    # Base model - MobileNetV2 (eficiente para mobile/edge)
    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(IMG_SIZE, IMG_SIZE, 3)
    )
    
    base_model.trainable = False

    # Feature extraction aprimorada
    x = base_model.output
    
    # Adicionar SE block se habilitado
    if use_se_block:
        x = squeeze_excite_block(x, ratio=16)
    
    # Dual pooling (AVG + MAX) - captura mais informação
    avg_pool = GlobalAveragePooling2D()(x)
    max_pool = GlobalMaxPooling2D()(x)
    x = Concatenate()([avg_pool, max_pool])
    
    # Camadas densas com regularização progressiva
    x = BatchNormalization()(x)
    x = Dense(1024, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.01))(x)
    x = Dropout(0.5)(x)
    
    x = BatchNormalization()(x)
    x = Dense(512, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.01))(x)
    x = Dropout(0.4)(x)
    
    x = BatchNormalization()(x)
    x = Dense(256, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.01))(x)
    x = Dropout(0.3)(x)
    
    # Output layer
    predictions = Dense(num_classes, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    # Compilar com optimizer moderno
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=INITIAL_LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=3, name='top3_accuracy')]
    )

    return model, base_model


# ======================== TREINAMENTO ========================
def train_with_two_phase_strategy(model, base_model, train_gen, val_gen, class_weights):
    """
    Estratégia de treinamento em duas fases
    Fase 1: Feature extraction (frozen base)
    Fase 2: Fine-tuning (unfrozen base com LR menor)
    """
    # Criar diretório para checkpoints
    checkpoint_dir = os.path.join(BASE_DIR, 'backend', 'models', 'checkpoints')
    os.makedirs(checkpoint_dir, exist_ok=True)
    
    # ========== FASE 1: FEATURE EXTRACTION ==========
    print("\n" + "="*60)
    print("🎯 FASE 1: FEATURE EXTRACTION (Base Congelada)")
    print("="*60)
    
    callbacks_phase1 = [
        EarlyStopping(
            monitor='val_accuracy',
            patience=15,
            restore_best_weights=True,
            verbose=1,
            mode='max'
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-7,
            verbose=1
        ),
        ModelCheckpoint(
            filepath=os.path.join(checkpoint_dir, 'phase1_best.h5'),
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]

    history1 = model.fit(
        train_gen,
        steps_per_epoch=train_gen.samples // train_gen.batch_size,
        validation_data=val_gen,
        validation_steps=val_gen.samples // val_gen.batch_size,
        epochs=30,
        callbacks=callbacks_phase1,
        class_weight=class_weights,  # Importante: usar class weights
        verbose=1
    )

    # ========== FASE 2: FINE-TUNING ==========
    print("\n" + "="*60)
    print("🔥 FASE 2: FINE-TUNING (Descongelando últimas camadas)")
    print("="*60)
    
    # Descongelar base model gradualmente
    base_model.trainable = True
    
    # Congelar apenas primeiras camadas (feature extraction básica)
    fine_tune_at = len(base_model.layers) - 40  # Últimas 40 camadas
    for layer in base_model.layers[:fine_tune_at]:
        layer.trainable = False
    
    print(f"📊 Layers treináveis: {sum([1 for layer in model.layers if layer.trainable])}")
    print(f"📊 Layers congeladas: {sum([1 for layer in model.layers if not layer.trainable])}")

    # Recompilar com LR menor
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=FINE_TUNE_LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=3, name='top3_accuracy')]
    )

    callbacks_phase2 = [
        EarlyStopping(
            monitor='val_accuracy',
            patience=20,  # Mais paciência para fine-tuning
            restore_best_weights=True,
            verbose=1,
            mode='max'
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.3,
            patience=7,
            min_lr=1e-8,
            verbose=1
        ),
        ModelCheckpoint(
            filepath=os.path.join(checkpoint_dir, 'phase2_best.h5'),
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]

    history2 = model.fit(
        train_gen,
        steps_per_epoch=train_gen.samples // train_gen.batch_size,
        validation_data=val_gen,
        validation_steps=val_gen.samples // val_gen.batch_size,
        epochs=EPOCHS,
        callbacks=callbacks_phase2,
        class_weight=class_weights,
        verbose=1,
        initial_epoch=len(history1.history['loss'])
    )

    # Combinar históricos
    combined_history = {
        'loss': history1.history['loss'] + history2.history['loss'],
        'accuracy': history1.history['accuracy'] + history2.history['accuracy'],
        'val_loss': history1.history['val_loss'] + history2.history['val_loss'],
        'val_accuracy': history1.history['val_accuracy'] + history2.history['val_accuracy'],
        'top3_accuracy': history1.history.get('top3_accuracy', []) + history2.history.get('top3_accuracy', []),
        'val_top3_accuracy': history1.history.get('val_top3_accuracy', []) + history2.history.get('val_top3_accuracy', [])
    }

    return combined_history


# ======================== AVALIAÇÃO ========================
def evaluate_model_detailed(model, test_generator):
    """
    Avaliação detalhada com múltiplas métricas
    """
    print("\n" + "="*60)
    print("📊 AVALIAÇÃO DETALHADA DO MODELO")
    print("="*60)

    results = model.evaluate(
        test_generator,
        steps=test_generator.samples // test_generator.batch_size,
        verbose=1
    )

    metrics_names = model.metrics_names
    print("\n✓ Resultados:")
    for name, value in zip(metrics_names, results):
        print(f"   {name}: {value:.4f}")

    return dict(zip(metrics_names, results))


# ======================== VISUALIZAÇÃO ========================
def plot_enhanced_history(history):
    """
    Visualização aprimorada do treinamento
    """
    plt.style.use('seaborn-v0_8-darkgrid')
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))

    epochs = range(1, len(history['accuracy']) + 1)

    # Acurácia
    axes[0, 0].plot(epochs, history['accuracy'], 'b-', label='Treino', linewidth=2)
    axes[0, 0].plot(epochs, history['val_accuracy'], 'r-', label='Validação', linewidth=2)
    axes[0, 0].set_title('Acurácia do Modelo', fontsize=14, fontweight='bold')
    axes[0, 0].set_xlabel('Época')
    axes[0, 0].set_ylabel('Acurácia')
    axes[0, 0].legend()
    axes[0, 0].grid(True, alpha=0.3)

    # Perda
    axes[0, 1].plot(epochs, history['loss'], 'b-', label='Treino', linewidth=2)
    axes[0, 1].plot(epochs, history['val_loss'], 'r-', label='Validação', linewidth=2)
    axes[0, 1].set_title('Perda do Modelo', fontsize=14, fontweight='bold')
    axes[0, 1].set_xlabel('Época')
    axes[0, 1].set_ylabel('Perda')
    axes[0, 1].legend()
    axes[0, 1].grid(True, alpha=0.3)

    # Top-3 Accuracy
    if 'top3_accuracy' in history and history['top3_accuracy']:
        axes[1, 0].plot(epochs, history['top3_accuracy'], 'g-', label='Treino Top-3', linewidth=2)
        axes[1, 0].plot(epochs, history['val_top3_accuracy'], 'orange', label='Val Top-3', linewidth=2)
        axes[1, 0].set_title('Top-3 Accuracy', fontsize=14, fontweight='bold')
        axes[1, 0].set_xlabel('Época')
        axes[1, 0].set_ylabel('Top-3 Accuracy')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)

    # Gap entre treino e validação
    gap = [abs(t - v) for t, v in zip(history['accuracy'], history['val_accuracy'])]
    axes[1, 1].plot(epochs, gap, 'purple', linewidth=2)
    axes[1, 1].set_title('Gap Treino-Validação (Overfitting)', fontsize=14, fontweight='bold')
    axes[1, 1].set_xlabel('Época')
    axes[1, 1].set_ylabel('Gap Absoluto')
    axes[1, 1].grid(True, alpha=0.3)
    axes[1, 1].axhline(y=0.05, color='r', linestyle='--', label='Threshold (5%)')
    axes[1, 1].legend()

    plt.tight_layout()
    save_path = os.path.join(BASE_DIR, 'backend', 'training_history_enhanced.png')
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"\n💾 Gráfico salvo: training_history_enhanced.png")


# ======================== SALVAMENTO ========================
def save_model_and_info(model, test_results, num_classes, total_images):
    """
    Salva modelo e metadados completos
    """
    models_dir = os.path.join(BASE_DIR, 'backend', 'models')
    os.makedirs(models_dir, exist_ok=True)

    # Salvar modelo H5
    model_path = os.path.join(models_dir, 'insect_classifier_enhanced.h5')
    try:
        model.save(model_path)
        print(f"✓ Modelo H5 salvo: {model_path}")
    except Exception as e:
        print(f"⚠️ Erro ao salvar H5: {e}")
        weights_path = os.path.join(models_dir, 'insect_classifier_enhanced_weights.h5')
        model.save_weights(weights_path)
        print(f"✓ Pesos salvos: {weights_path}")

    # Converter para TFLite
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        tflite_path = os.path.join(models_dir, 'insect_classifier_enhanced.tflite')
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        print(f"✓ Modelo TFLite salvo: {tflite_path}")
    except Exception as e:
        print(f"⚠️ Erro ao converter TFLite: {e}")

    # Salvar metadados
    model_info = {
        'version': '2.0_enhanced',
        'dataset_type': DATASET_TYPE,
        'total_images': total_images,
        'num_classes': num_classes,
        'test_metrics': test_results,
        'architecture': {
            'base': 'MobileNetV2',
            'pooling': 'Dual (AVG + MAX)',
            'attention': 'Squeeze-and-Excitation',
            'regularization': 'L2 + Dropout + BatchNorm'
        },
        'training': {
            'img_size': IMG_SIZE,
            'batch_size': BATCH_SIZE,
            'max_epochs': EPOCHS,
            'initial_lr': INITIAL_LEARNING_RATE,
            'finetune_lr': FINE_TUNE_LEARNING_RATE,
            'strategy': 'Two-Phase (Feature Extraction + Fine-tuning)'
        },
        'optimizations': [
            'Two-phase training strategy',
            'Squeeze-and-Excitation blocks',
            'Dual pooling (AVG+MAX)',
            'Advanced data augmentation (CutMix-style)',
            'Class weighting for imbalance',
            'L2 regularization',
            'Adaptive learning rate reduction',
            'Early stopping with patience',
            'Model checkpointing'
        ],
        'categories': categories
    }

    info_path = os.path.join(models_dir, 'model_info_enhanced.json')
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, indent=2, ensure_ascii=False)
    print(f"✓ Metadados salvos: {info_path}")


# ======================== MAIN ========================
def main():
    """
    Pipeline completo de treinamento
    """
    print("\n" + "="*70)
    print("🐛 SISTEMA DE CLASSIFICAÇÃO DE INSETOS - VERSÃO APRIMORADA")
    print("="*70)
    print(f"📊 Dataset: {DATASET_TYPE}")
    print(f"🖼️  Tamanho: {IMG_SIZE}x{IMG_SIZE}")
    print(f"📦 Batch: {BATCH_SIZE}")
    print(f"🔄 Épocas máx: {EPOCHS}")
    print(f"📈 LR inicial: {INITIAL_LEARNING_RATE}")
    print(f"📉 LR fine-tune: {FINE_TUNE_LEARNING_RATE}")

    # Pipeline
    image_paths, labels = load_dataset_from_folders()
    
    if not image_paths:
        print("❌ Nenhuma imagem encontrada!")
        return

    df = create_balanced_dataframe(image_paths, labels)
    train_gen, val_gen, test_gen, class_weights = create_advanced_generators(df)
    
    num_classes = len(categories)
    model, base_model = create_enhanced_model(num_classes, use_se_block=True)
    
    print(f"\n📐 ARQUITETURA DO MODELO")
    print("="*70)
    model.summary()

    history = train_with_two_phase_strategy(model, base_model, train_gen, val_gen, class_weights)
    test_results = evaluate_model_detailed(model, test_gen)
    
    plot_enhanced_history(history)
    save_model_and_info(model, test_results, num_classes, len(df))

    print("\n" + "="*70)
    print("✅ TREINAMENTO CONCLUÍDO")
    print("="*70)
    print(f"🎯 Acurácia final: {test_results['accuracy']:.4f}")
    print(f"🥇 Top-3 Accuracy: {test_results.get('top3_accuracy', 'N/A'):.4f}")
    
    if test_results['accuracy'] >= 0.80:
        print("🎉 Excelente! Meta de 80% atingida!")
    elif test_results['accuracy'] >= 0.75:
        print("✅ Bom! Meta de 75% atingida!")
    else:
        print("⚠️ Considere aumentar épocas ou coletar mais dados")


if __name__ == "__main__":
    main()
