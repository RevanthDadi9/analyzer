const express = require('express');
const multer = require('multer');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs');
const pdfParse = require('pdf-parse');

const app = express();
const upload = multer({ dest: 'uploads/' });
app.use(cors());
app.use(express.json());
app.get('/upload', function (req, res) {
  res.send('Apple API! v0.5');
});
app.post('/', upload.single('file'), async (req, res) => {
  const filePath = req.file.path;
  const fileMime = req.file.mimetype;

  let text = '';

  try {
    if (fileMime === 'application/pdf') {
      const pdfData = fs.readFileSync(filePath);
      const parsed = await pdfParse(pdfData);
      text = parsed.text;
    } else {
      // fallback to plain text
      text = fs.readFileSync(filePath, 'utf8');
    }
    
    const response = await axios.post('http://10.0.0.4:8000/analyze', {
      content: text
    });

    fs.unlinkSync(filePath); // clean up

    res.json(response.data);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Analysis failed' });
  }
});

app.listen(5013, '0.0.0.0', () => {
  console.log('Backend listening on port 5013');
});
