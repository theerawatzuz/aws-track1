const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
app.get('/', (_, res) => res.send('Hello from GitHub v2 Pipeline!'));
app.listen(port, () => console.log(`Server running on ${port}`));
