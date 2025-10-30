# 🦋 Documentação Completa do Sistema de Classificação de Insetos

## 📋 Visão Geral

Este sistema é uma solução completa para coleta, processamento e classificação de insetos usando dados do iNaturalist e modelos de Machine Learning. O sistema é composto por 4 módulos principais que trabalham em conjunto.

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    SISTEMA COMPLETO                        │
├─────────────────────────────────────────────────────────────┤
│  📊 COLETA    │  🔧 PROCESSAMENTO  │  🤖 TREINAMENTO  │  🌐 API  │
│               │                    │                  │         │
│ iNaturalist   │ Validação &        │ TensorFlow/      │ Flask   │
│ Collector     │ Organização        │ Keras            │ Server  │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Fluxo de Dados

### **1️⃣ Coleta (iNaturalist Collector)**

```
iNaturalist API → backend/enhanced_insect_data/raw_data/
```

- **Entrada**: API do iNaturalist
- **Saída**: Dados brutos em `backend/enhanced_insect_data/raw_data/`
- **Conteúdo**: ~19.710 imagens brutas + metadados

### **2️⃣ Processamento (Data Processor)**

```
backend/enhanced_insect_data/raw_data/ → enhanced_insect_data/enhanced_dataset/
```

- **Entrada**: Dados brutos do backend
- **Saída**: Dataset final na raiz do projeto
- **Processamento**:
  - ✅ Validação de qualidade (blur, brilho, tamanho)
  - ✅ Remoção de duplicatas
  - ✅ Balanceamento de classes
  - ✅ Seleção das melhores imagens
- **Resultado**: ~3.218 imagens otimizadas

### **3️⃣ Treinamento (Train Model)**

```
enhanced_insect_data/enhanced_dataset/ → models/
```

- **Entrada**: Dataset processado da raiz
- **Saída**: Modelos treinados em `models/`
- **Resultado**: Modelo .tflite otimizado

## 🔧 Como Usar o Data Processor

### **Comando Básico:**

```bash
python data_processor.py
```

### **Comando Completo:**

```bash
python data_processor.py --input-dir backend/enhanced_insect_data --output-dir ../enhanced_insect_data/enhanced_dataset --max-images 400
```

### **O que o Data Processor faz:**

1. **📁 Lê dados brutos** de `backend/enhanced_insect_data/raw_data/`
2. **🔍 Valida qualidade** de cada imagem:
   - Tamanho mínimo (100x100px)
   - Blur score (não muito desfocada)
   - Brilho adequado (não muito escura/clara)
3. **🔄 Remove duplicatas** usando hash MD5
4. **📊 Seleciona as melhores** imagens por qualidade
5. **📁 Salva na raiz** em `enhanced_insect_data/enhanced_dataset/`

### **Resultado:**

- **Antes**: 19.710 imagens brutas (qualidade variável)
- **Depois**: 3.218 imagens otimizadas (qualidade garantida)
- **Melhoria**: Dataset balanceado e pronto para treinamento

## 📁 Estrutura de Arquivos

### 🔧 **Scripts Principais**

| Arquivo                    | Função           | Descrição                                     |
| -------------------------- | ---------------- | --------------------------------------------- |
| `app.py`                   | **API Server**   | Servidor Flask para classificação de imagens  |
| `collect_insect_data.py`   | **Orquestrador** | Script principal que coordena todo o processo |
| `inaturalist_collector.py` | **Coletor**      | Busca e baixa dados do iNaturalist            |
| `data_processor.py`        | **Processador**  | Valida e organiza dados coletados             |
| `train_model.py`           | **Treinador**    | Treina modelos de classificação               |

### 📂 **Diretórios de Dados**

| Diretório                       | Conteúdo                                         | Uso                         |
| ------------------------------- | ------------------------------------------------ | --------------------------- |
| `data/`                         | Listas de espécies por categoria                 | Referência para coleta      |
| `backend/enhanced_insect_data/` | **Dados brutos** coletados (raw_data + metadata) | Processamento intermediário |
| `enhanced_insect_data/`         | **Dataset final** processado e otimizado         | Dataset para treinamento    |
| `models/`                       | Modelos treinados (.tflite)                      | Classificação em produção   |

### ⚙️ **Configuração e Deploy**

| Arquivo                      | Função                   |
| ---------------------------- | ------------------------ |
| `requirements.txt`           | Dependências básicas     |
| `requirements_collector.txt` | Dependências para coleta |
| `Dockerfile`                 | Containerização          |
| `Procfile`                   | Deploy em produção       |

---

## 🔄 Fluxo Completo do Sistema

### **Fase 1: Coleta de Dados** 📊

**Arquivo:** `inaturalist_collector.py`

**Processo:**

1. **Busca no iNaturalist**: Conecta à API do iNaturalist
2. **Filtragem**: Busca apenas observações de insetos específicos
3. **Download**: Baixa imagens em paralelo
4. **Validação**: Verifica qualidade básica das imagens
5. **Organização**: Salva em estrutura hierárquica

**Classes Suportadas:**

- Aranhas, Besouros Carabídeos, Crisopídeos
- Joaninhas, Libélulas, Moscas (4 tipos)
- Percevejos (4 tipos), Tesourinhas
- Vespas Parasitoides e Predadoras

**Funcionalidades:**

- ✅ Rate limiting para respeitar API
- ✅ Download paralelo otimizado
- ✅ Detecção de duplicatas
- ✅ Validação de qualidade
- ✅ Retry automático em falhas
- ✅ Logs detalhados

### **Fase 2: Processamento** 🔧

**Arquivo:** `data_processor.py`

**Processo:**

1. **Validação Avançada**: Verifica blur, brilho, tamanho
2. **Remoção de Duplicatas**: Usa hash para identificar duplicatas
3. **Balanceamento**: Organiza dados por classe
4. **Relatórios**: Gera estatísticas e visualizações
5. **Dataset Final**: Cria estrutura otimizada para treinamento

**Validações:**

- ✅ Detecção de blur (Laplacian)
- ✅ Verificação de brilho
- ✅ Tamanho mínimo de imagem
- ✅ Formato válido
- ✅ Hash para duplicatas

### **Fase 3: Treinamento** 🤖

**Arquivo:** `train_model.py`

**Processo:**

1. **Pré-processamento**: Otimização para imagens de celular
2. **Modelo**: EfficientNetB0 (transfer learning)
3. **Treinamento**: Com balanceamento de classes
4. **Validação**: Métricas de acurácia
5. **Exportação**: Conversão para TFLite

**Características:**

- ✅ EfficientNetB0 (state-of-the-art)
- ✅ Transfer learning
- ✅ Data augmentation
- ✅ Class balancing
- ✅ Mobile optimization
- ✅ TFLite export

### **Fase 4: API de Classificação** 🌐

**Arquivo:** `app.py`

**Endpoints:**

- `POST /classify` - Classifica imagem de inseto
- `GET /species` - Lista classes disponíveis
- `GET /images/<species>` - Galeria de imagens
- `POST /feedback` - Coleta feedback dos usuários
- `GET /feedback/stats` - Estatísticas de feedback

**Funcionalidades:**

- ✅ Classificação em tempo real
- ✅ CORS habilitado
- ✅ Sistema de feedback
- ✅ Estatísticas de uso
- ✅ Servir imagens estáticas

---

## 🚀 Como Usar o Sistema

### **1. Instalação**

```bash
# Dependências básicas
pip install -r requirements.txt

# Dependências para coleta
pip install -r requirements_collector.txt
```

### **2. Coleta de Dados**

```bash
# Coleta completa
python collect_insect_data.py --action full

# Coleta de uma classe específica
python collect_insect_data.py --action collect --class-name aranhas --max-observations 100

# Apenas processar dados existentes
python collect_insect_data.py --action process
```

### **3. Treinamento**

```bash
# Treinar com dados processados
python train_model.py --data-dir enhanced_insect_data/processed_dataset

# Treinar com dataset específico
python train_model.py --data-dir ../enhanced_insect_data/enhanced_dataset
```

### **4. API**

```bash
# Iniciar servidor
python app.py

# Testar classificação
curl -X POST -F "image=@inseto.jpg" http://localhost:5000/classify
```

---

## 📊 Classes de Insetos Suportadas

| Classe                       | Nome Científico | Descrição                 |
| ---------------------------- | --------------- | ------------------------- |
| **Aranhas**                  | Araneae         | Aranhas em geral          |
| **Besouros Carabídeos**      | Carabidae       | Besouros predadores       |
| **Crisopídeos**              | Chrysopidae     | Insetos verdes predadores |
| **Joaninhas**                | Coccinellidae   | Besouros coloridos        |
| **Libélulas**                | Odonata         | Insetos aquáticos         |
| **Moscas Asilídeas**         | Asilidae        | Moscas predadoras         |
| **Moscas Delicopodídeas**    | Dolichopodidae  | Moscas pequenas           |
| **Moscas Sirfídeas**         | Syrphidae       | Moscas polinizadoras      |
| **Moscas Taquinídeas**       | Tachinidae      | Moscas parasitoides       |
| **Percevejos Geocoris**      | Geocoris        | Percevejos predadores     |
| **Percevejos Orius**         | Orius           | Percevejos pequenos       |
| **Percevejos Pentatomídeos** | Pentatomidae    | Percevejos grandes        |
| **Percevejos Reduviídeos**   | Reduviidae      | Percevejos assassinos     |
| **Tesourinhas**              | Dermaptera      | Insetos com pinças        |
| **Vespas Parasitoides**      | Parasitica      | Vespas parasitoides       |
| **Vespas Predadoras**        | Vespidae        | Vespas sociais            |

---

## 🔧 Configurações Avançadas

### **Parâmetros de Coleta**

```python
# Em inaturalist_collector.py
MAX_OBSERVATIONS_PER_CLASS = 1000  # Máximo por classe
MIN_IMAGE_SIZE = (100, 100)        # Tamanho mínimo
MAX_WORKERS = 2                     # Threads paralelos
RATE_LIMIT_DELAY = 1.0             # Delay entre requests
```

### **Parâmetros de Treinamento**

```python
# Em train_model.py
TARGET_SIZE = (224, 224)           # Tamanho da imagem
BATCH_SIZE = 32                    # Batch size
EPOCHS = 50                        # Épocas de treinamento
LEARNING_RATE = 0.001              # Taxa de aprendizado
```

### **Parâmetros da API**

```python
# Em app.py
PORT = 5000                        # Porta do servidor
HOST = '0.0.0.0'                  # Host do servidor
CORS_ORIGINS = "*"                # Origens permitidas
```

---

## 📈 Monitoramento e Logs

### **Arquivos de Log**

| Log                         | Descrição             |
| --------------------------- | --------------------- |
| `inaturalist_collector.log` | Logs da coleta        |
| `data_processor.log`        | Logs do processamento |
| `collect_insect_data.log`   | Logs do pipeline      |
| `feedback_data.json`        | Feedback dos usuários |

### **Métricas Disponíveis**

- ✅ Taxa de sucesso de download
- ✅ Qualidade das imagens coletadas
- ✅ Acurácia do modelo
- ✅ Feedback dos usuários
- ✅ Estatísticas de uso

---

## 🐳 Deploy com Docker

### **Dockerfile**

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

### **Comandos Docker**

```bash
# Build
docker build -t insect-classifier .

# Run
docker run -p 5000:5000 insect-classifier
```

---

## 🔍 Troubleshooting

### **Problemas Comuns**

1. **WinError 32**: Arquivo em uso

   - Solução: Reduzir `max_workers` para 1-2

2. **Rate Limit**: Muitas requisições

   - Solução: Aumentar `RATE_LIMIT_DELAY`

3. **Memória Insuficiente**: Treinamento falha

   - Solução: Reduzir `BATCH_SIZE`

4. **Unicode Error**: Emojis no Windows
   - Solução: Remover emojis dos logs

### **Logs de Debug**

```bash
# Verificar logs
tail -f inaturalist_collector.log
tail -f data_processor.log
tail -f collect_insect_data.log
```

---

## 📚 Dependências

### **Core Dependencies**

- `tensorflow>=2.10.0` - Machine Learning
- `flask>=2.0.0` - API Server
- `requests>=2.28.0` - HTTP requests
- `Pillow>=9.0.0` - Image processing
- `opencv-python>=4.6.0` - Computer vision
- `numpy>=1.21.0` - Numerical computing
- `pandas>=1.4.0` - Data manipulation

### **Optional Dependencies**

- `matplotlib>=3.5.0` - Visualization
- `seaborn>=0.11.0` - Statistical plots
- `tqdm>=4.64.0` - Progress bars

---

## 🎯 Próximos Passos

### **Melhorias Futuras**

1. **Modelo**: Implementar EfficientNetV2
2. **API**: Adicionar autenticação
3. **Coleta**: Implementar coleta contínua
4. **Feedback**: Sistema de aprendizado ativo
5. **Mobile**: App nativo para Android/iOS

### **Integração**

- ✅ **Flutter App**: Já integrado
- ✅ **Web Interface**: Disponível
- ✅ **API REST**: Funcional
- ✅ **Docker**: Containerizado

---

## 📞 Suporte

Para dúvidas ou problemas:

1. Verificar logs de erro
2. Consultar esta documentação
3. Verificar dependências
4. Testar com dados menores

**Sistema desenvolvido para classificação de insetos com alta precisão! 🦋**
