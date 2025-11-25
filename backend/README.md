# Sistema de Coleta e Classificação de Insetos

Sistema completo para coleta de dados de insetos do iNaturalist e treinamento de modelos de classificação.

## 🚀 Funcionalidades

- **Coleta de Dados**: Busca e download de imagens de insetos do iNaturalist
- **Processamento**: Validação de qualidade e organização dos dados
- **Treinamento**: Modelos de classificação com TensorFlow/Keras
- **API**: Servidor Flask para classificação de imagens

## 📁 Estrutura

```
backend/
├── app.py                    # API Flask para classificação
├── collect_insect_data.py    # Script principal de coleta
├── data_processor.py         # Processamento e validação de dados
├── inaturalist_collector.py  # Coletor do iNaturalist
├── train_model.py           # Treinamento do modelo
├── data/                    # Listas de espécies por categoria
├── enhanced_insect_data/    # Dados coletados e processados
├── models/                  # Modelos treinados
└── requirements.txt         # Dependências
```

## 🛠️ Instalação

```bash
# Instalar dependências
pip install -r requirements.txt

# Para coleta de dados (dependências extras)
pip install -r requirements_collector.txt
```

## 📊 Uso

### Coleta de Dados

```bash
# Coleta completa
python collect_insect_data.py --action full

# Coleta de uma classe específica
python collect_insect_data.py --action collect --class-name aranhas --max-observations 100

# Apenas processar dados existentes
python collect_insect_data.py --action process
```

### Treinamento

```bash
# Treinar modelo
python train_model.py

# Treinar com dados específicos
python train_model.py --data-dir enhanced_insect_data/processed_dataset
```

### API

```bash
# Iniciar servidor
python app.py
```

## 🎯 Classes de Insetos

- **Aranhas** (Araneae)
- **Besouros Carabídeos** (Carabidae)
- **Crisopídeos** (Chrysopidae)
- **Joaninhas** (Coccinellidae)
- **Libélulas** (Odonata)
- **Moscas Asilídeas** (Asilidae)
- **Moscas Delicopodídeas** (Dolichopodidae)
- **Moscas Sirfídeas** (Syrphidae)
- **Moscas Taquinídeas** (Tachinidae)
- **Percevejos Geocoris** (Geocoris)
- **Percevejos Orius** (Orius)
- **Percevejos Pentatomídeos** (Pentatomidae)
- **Percevejos Reduviídeos** (Reduviidae)
- **Tesourinhas** (Dermaptera)
- **Vespas Parasitoides** (Parasitica)
- **Vespas Predadoras** (Vespidae)

## 📈 Status

- ✅ Sistema de coleta funcionando
- ✅ Processamento de dados implementado
- ✅ Treinamento de modelos configurado
- ✅ API de classificação ativa

## 🔧 Configuração

O sistema usa configurações padrão que podem ser ajustadas nos scripts principais. Para personalizar:

1. **Coleta**: Ajuste `max_observations` e `max_images` em `collect_insect_data.py`
2. **Treinamento**: Modifique parâmetros em `train_model.py`
3. **API**: Configure porta e host em `app.py`

## 📝 Logs

Os logs são salvos automaticamente em arquivos `.log` para cada componente do sistema.
