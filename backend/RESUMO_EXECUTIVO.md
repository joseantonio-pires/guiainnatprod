# 📋 Resumo Executivo - Sistema de Classificação de Insetos

## 🎯 **Objetivo**

Sistema completo para coleta, processamento e classificação de insetos usando dados do iNaturalist e Machine Learning.

## 📁 **Arquivos Principais**

### 🔧 **Core System**

| Arquivo                    | Função                                       | Status           |
| -------------------------- | -------------------------------------------- | ---------------- |
| `app.py`                   | **API Server** - Classificação em tempo real | ✅ **Produção**  |
| `collect_insect_data.py`   | **Orquestrador** - Coordena todo o processo  | ✅ **Funcional** |
| `inaturalist_collector.py` | **Coletor** - Busca dados do iNaturalist     | ✅ **Funcional** |
| `data_processor.py`        | **Processador** - Valida e organiza dados    | ✅ **Funcional** |
| `train_model.py`           | **Treinador** - Treina modelos ML            | ✅ **Funcional** |

### 📊 **Dados e Configuração**

| Diretório/Arquivo            | Conteúdo                         | Uso                       |
| ---------------------------- | -------------------------------- | ------------------------- |
| `data/`                      | Listas de espécies por categoria | Referência para coleta    |
| `enhanced_insect_data/`      | Dados coletados (~25k imagens)   | Dataset para treinamento  |
| `models/`                    | Modelos treinados (.tflite)      | Classificação em produção |
| `requirements.txt`           | Dependências básicas             | Instalação                |
| `requirements_collector.txt` | Dependências para coleta         | Coleta de dados           |

### 🚀 **Deploy**

| Arquivo      | Função             |
| ------------ | ------------------ |
| `Dockerfile` | Containerização    |
| `Procfile`   | Deploy em produção |
| `.gitignore` | Controle de versão |

---

## 🔄 **Fluxo de Trabalho**

### **1. Coleta** 📊

```bash
python collect_insect_data.py --action collect --class-name aranhas
```

- Busca no iNaturalist
- Download de imagens
- Validação básica

### **2. Processamento** 🔧

```bash
python collect_insect_data.py --action process
```

- Validação avançada
- Remoção de duplicatas
- Organização final

### **3. Treinamento** 🤖

```bash
python train_model.py --data-dir enhanced_insect_data/enhanced_dataset
```

- EfficientNetB0
- Transfer learning
- Exportação TFLite

### **4. API** 🌐

```bash
python app.py
```

- Classificação em tempo real
- Sistema de feedback
- Estatísticas

---

## 📈 **Status Atual**

### ✅ **Funcionando**

- Sistema de coleta completo
- Processamento de dados
- Treinamento de modelos
- API de classificação
- Integração com Flutter

### 📊 **Dados Disponíveis**

- **~25.000 imagens** coletadas
- **16 classes** de insetos
- **Dataset balanceado** para treinamento
- **Modelos treinados** prontos

### 🎯 **Classes Suportadas**

Aranhas, Besouros, Crisopídeos, Joaninhas, Libélulas, Moscas (4 tipos), Percevejos (4 tipos), Tesourinhas, Vespas (2 tipos)

---

## 🚀 **Como Usar**

### **Para Coletar Dados:**

```bash
cd backend
pip install -r requirements_collector.txt
python collect_insect_data.py --action full
```

### **Para Treinar Modelo:**

```bash
python train_model.py
```

### **Para Usar API:**

```bash
python app.py
# Acesse: http://localhost:5000
```

---

## 🔧 **Configurações Importantes**

### **Coleta**

- `MAX_OBSERVATIONS_PER_CLASS = 1000`
- `MAX_WORKERS = 2` (Windows)
- `RATE_LIMIT_DELAY = 1.0`

### **Treinamento**

- `TARGET_SIZE = (224, 224)`
- `BATCH_SIZE = 32`
- `EPOCHS = 50`

### **API**

- `PORT = 5000`
- `HOST = '0.0.0.0'`

---

## 📝 **Logs e Monitoramento**

| Log                         | Descrição         |
| --------------------------- | ----------------- |
| `inaturalist_collector.log` | Coleta de dados   |
| `data_processor.log`        | Processamento     |
| `collect_insect_data.log`   | Pipeline completo |
| `feedback_data.json`        | Feedback usuários |

---

## 🎯 **Próximos Passos**

1. **Usar dados existentes** para treinamento
2. **Coletar mais dados** se necessário
3. **Otimizar modelo** com novos dados
4. **Deploy em produção**

---

## 💡 **Dicas Importantes**

- ✅ Use `enhanced_insect_data/enhanced_dataset/` para treinamento
- ✅ Dados já estão processados e balanceados
- ✅ Sistema funciona sem backup (opcional)
- ✅ Logs sem emojis para Windows
- ✅ Rate limiting implementado

**Sistema completo e pronto para uso! 🦋**
