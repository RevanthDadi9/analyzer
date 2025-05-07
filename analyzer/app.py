from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import pipeline

app = Flask(__name__)
CORS(app)

# Load the summarization pipeline
summarizer = pipeline("summarization", model="facebook/bart-large-cnn")

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json()
    content = data.get('content', '')

    if not content.strip():
        return jsonify({'error': 'Empty content'}), 400

    try:
        # Limit input for large files (e.g., max 1024 tokens)
        chunks = [content[i:i+1000] for i in range(0, len(content), 1000)]
        summaries = [summarizer(chunk, max_length=130, min_length=30, do_sample=False)[0]['summary_text'] for chunk in chunks]
        full_summary = ' '.join(summaries)

        return jsonify({
            'summary': full_summary,
            'word_count': len(content.split()),
            'line_count': len(content.split('\n')),
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(port=8000)
