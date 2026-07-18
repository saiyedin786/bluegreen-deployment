const express = require("express");

const app = express();

const version = process.env.APP_VERSION || "blue";

app.get("/", (req, res) => {
    console.log("Request received");
    res.send(`Application Version : ${version}`);
});

app.listen(3000, "0.0.0.0", () => {
    console.log("Server Running on port 3000");
});