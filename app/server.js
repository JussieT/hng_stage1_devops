const express = require('express');
const app = express();
const PORT = 8080;

app.get('/', (req, res) => {
  res.send('🚀 Hello from your Dockerized App running on AWS EC2!');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});