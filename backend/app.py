import tensorflow as tf
from flask import Flask, request, jsonify, send_file, send_from_directory
from flask_cors import CORS
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import img_to_array
from PIL import Image
import numpy as np
import io
import os
import json
from datetime import datetime

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Verifica se a pasta galerias está dentro do container (Docker)
if os.path.exists(os.path.join(BASE_DIR, 'galerias')):
    GALERIAS_DIR = os.path.join(BASE_DIR, 'galerias')  # Docker
else:
    GALERIAS_DIR = os.path.abspath(
        os.path.join(BASE_DIR, '..', 'galerias'))  # Local
app.static_folder = GALERIAS_DIR

# Carregar o modelo
model_path = os.path.join(
    BASE_DIR, 'models', 'insect_classifier.tflite')
# Para TFLite, usaremos o interpretador
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

# Obter detalhes de entrada e saída
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

categories = ['aranhas', 'besouro_carabideo', 'crisopideo', 'joaninhas', 'libelulas',
              'mosca_asilidea', 'mosca_dolicopodidea', 'mosca_sirfidea', 'mosca_taquinidea',
              'percevejo_geocoris', 'percevejo_orius', 'percevejo_pentatomideo',
              'percevejo_reduviideo', 'tesourinha', 'vespa_parasitoide', 'vespa_predadora']


@app.route('/classify', methods=['POST'])
def classify_insect():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    try:
        image = request.files['image'].read()
        image = Image.open(io.BytesIO(image)).convert('RGB')
        image = image.resize((224, 224))
        image_array = img_to_array(image)
        image_array = np.expand_dims(image_array, axis=0)

        # Normalização ImageNet
        image_array = image_array.astype(np.float32) / 255.0
        mean = np.array([0.485, 0.456, 0.406])
        std = np.array([0.229, 0.224, 0.225])
        image_array = (image_array - mean) / std

        # Usar TFLite interpreter
        interpreter.set_tensor(input_details[0]['index'], image_array)
        interpreter.invoke()

        predictions = interpreter.get_tensor(output_details[0]['index'])
        predicted_class = categories[np.argmax(predictions[0])]
        confidence = float(np.max(predictions[0]))

        return jsonify({
            'predicted_class': predicted_class,
            'confidence': confidence
        })
    except Exception as e:
        return jsonify({'error': f'Classification failed: {str(e)}'}), 500


@app.route('/images/<species>', methods=['GET'])
def get_images(species):
    image_dir = os.path.join(GALERIAS_DIR, species)  # Usa o caminho absoluto
    if not os.path.exists(image_dir):
        return jsonify({'error': 'Species not found'}), 404

    images = [f for f in os.listdir(image_dir) if f.lower(
    ).startswith('imagem') and f.lower().endswith('.jpg')]
    # Ordena numericamente
    images.sort(key=lambda x: int(''.join(filter(str.isdigit, x))))
    image_urls = [f'/galerias/{species}/{img}' for img in images]
    return jsonify(image_urls)


@app.route('/galerias/<path:filename>')
def serve_image(filename):
    print(f"Tentando acessar: {os.path.join(GALERIAS_DIR, filename)}")  # Debug
    return send_from_directory(GALERIAS_DIR, filename)


@app.route('/species', methods=['GET'])
def get_species():
    return jsonify(categories)


@app.route('/feedback', methods=['POST'])
def register_feedback():
    """
    Registra feedback do usuário sobre a classificação
    """
    try:
        data = request.get_json()

        # Validação dos dados obrigatórios
        required_fields = ['image_id', 'predicted_class',
                           'user_feedback', 'confidence']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Campo obrigatório ausente: {field}'}), 400

        # Criar estrutura do feedback
        feedback_data = {
            'image_id': data['image_id'],
            'predicted_class': data['predicted_class'],
            'user_feedback': data['user_feedback'],  # 'correct' ou 'incorrect'
            # Se incorreto, qual a classe correta
            'correct_class': data.get('correct_class', None),
            'confidence': data['confidence'],
            'timestamp': datetime.now().isoformat(),
            'device_info': data.get('device_info', {}),
            'location': data.get('location', {})
        }

        # Salvar feedback em arquivo JSON
        feedback_file = os.path.join(BASE_DIR, 'feedback_data.json')

        # Carregar feedbacks existentes
        if os.path.exists(feedback_file):
            with open(feedback_file, 'r', encoding='utf-8') as f:
                feedbacks = json.load(f)
        else:
            feedbacks = []

        # Adicionar novo feedback
        feedbacks.append(feedback_data)

        # Salvar feedbacks atualizados
        with open(feedback_file, 'w', encoding='utf-8') as f:
            json.dump(feedbacks, f, indent=2, ensure_ascii=False)

        return jsonify({
            'success': True,
            'message': 'Feedback registrado com sucesso',
            'feedback_id': len(feedbacks) - 1
        })

    except Exception as e:
        return jsonify({'error': f'Erro ao registrar feedback: {str(e)}'}), 500


@app.route('/feedback/stats', methods=['GET'])
def get_feedback_stats():
    """
    Retorna estatísticas dos feedbacks recebidos
    """
    try:
        feedback_file = os.path.join(BASE_DIR, 'feedback_data.json')

        if not os.path.exists(feedback_file):
            return jsonify({
                'total_feedbacks': 0,
                'accuracy_rate': 0,
                'class_accuracy': {},
                'recent_feedbacks': []
            })

        with open(feedback_file, 'r', encoding='utf-8') as f:
            feedbacks = json.load(f)

        # Calcular estatísticas
        total_feedbacks = len(feedbacks)
        correct_feedbacks = sum(
            1 for f in feedbacks if f['user_feedback'] == 'correct')
        accuracy_rate = (correct_feedbacks / total_feedbacks *
                         100) if total_feedbacks > 0 else 0

        # Acurácia por classe
        class_accuracy = {}
        for feedback in feedbacks:
            predicted_class = feedback['predicted_class']
            if predicted_class not in class_accuracy:
                class_accuracy[predicted_class] = {'correct': 0, 'total': 0}

            class_accuracy[predicted_class]['total'] += 1
            if feedback['user_feedback'] == 'correct':
                class_accuracy[predicted_class]['correct'] += 1

        # Calcular percentual de acurácia por classe
        for class_name in class_accuracy:
            total = class_accuracy[class_name]['total']
            correct = class_accuracy[class_name]['correct']
            class_accuracy[class_name]['accuracy_rate'] = (
                correct / total * 100) if total > 0 else 0

        # Feedbacks recentes (últimos 10)
        recent_feedbacks = sorted(
            feedbacks, key=lambda x: x['timestamp'], reverse=True)[:10]

        return jsonify({
            'total_feedbacks': total_feedbacks,
            'accuracy_rate': round(accuracy_rate, 2),
            'class_accuracy': class_accuracy,
            'recent_feedbacks': recent_feedbacks
        })

    except Exception as e:
        return jsonify({'error': f'Erro ao obter estatísticas: {str(e)}'}), 500


# app.config['DEBUG'] = True  # Habilita o modo de depuração
if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
