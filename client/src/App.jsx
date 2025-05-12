import React, { useState } from 'react';
import axios from 'axios';
import { ArrowUpTrayIcon } from '@heroicons/react/24/outline';

function App() {
  const [file, setFile] = useState(null);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = async () => {
    if (!file) return alert("Please choose a file.");

    const formData = new FormData();
    formData.append('file', file);
    setLoading(true);
    setResult(null);

    try {
      const response = await axios.post('http://10.0.1.5:5013/upload', formData);
      setResult(response.data);
    } catch (err) {
      alert("Failed to analyze file.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 text-gray-800 flex items-center justify-center px-4">
      <div className="max-w-2xl w-full bg-white rounded-2xl shadow-lg p-8 space-y-6">
        <h1 className="text-3xl font-bold text-blue-600 text-center">🧠 Smart File Analyzer</h1>

        <label className="flex flex-col items-center justify-center border-2 border-dashed border-blue-400 p-6 rounded-lg cursor-pointer hover:bg-blue-50 transition">
          <ArrowUpTrayIcon className="h-8 w-8 text-blue-500 mb-2" />
          <span className="text-gray-600">Click to choose file</span>
          <input type="file" className="hidden" onChange={handleFileChange} />
        </label>

        {file && (
          <p className="text-sm text-center text-gray-500">Selected File: <strong>{file.name}</strong></p>
        )}

        <button
          onClick={handleUpload}
          disabled={loading}
          className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition font-medium"
        >
          {loading ? "Analyzing..." : "Upload & Analyze"}
        </button>

        {result && (
          <div className="bg-gray-100 p-4 rounded-lg shadow-inner space-y-2">
            <h2 className="text-xl font-semibold">📊 Analysis Result</h2>
            <p><strong>Word Count:</strong> {result.word_count}</p>
            <p><strong>Line Count:</strong> {result.line_count}</p>

            {result.summary && (
              <>
                <h3 className="mt-4 font-semibold">📝 Summary:</h3>
                <p className="whitespace-pre-wrap text-gray-700">{result.summary}</p>
              </>
            )}

            {result.keywords && (
              <>
                <h3 className="mt-4 font-semibold">🔑 Keywords:</h3>
                <div className="flex flex-wrap gap-2">
                  {result.keywords.map((word, i) => (
                    <span key={i} className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-sm">
                      {word}
                    </span>
                  ))}
                </div>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
