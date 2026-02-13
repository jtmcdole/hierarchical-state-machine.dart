const https = require('https');
const fs = require('fs');
const path = require('path');
const { encode } = require('./encode.cjs');

const SERVER = 'https://plantuml.mcdole.org/png/';

async function visualize(pumlText, outputPath) {
    const encoded = encode(pumlText);
    const url = SERVER + encoded;
    
    console.log(`URL: ${url}`);
    
    if (!outputPath) {
        return url;
    }

    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(outputPath);
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                reject(new Error(`Failed to fetch image: ${response.statusCode}`));
                return;
            }
            response.pipe(file);
            file.on('finish', () => {
                file.close();
                console.log(`Saved to: ${outputPath}`);
                resolve(url);
            });
        }).on('error', (err) => {
            fs.unlink(outputPath, () => {});
            reject(err);
        });
    });
}

async function main() {
    let pumlText = process.argv[2];
    let outputPath = process.argv[3];

    // Check if input is a file path
    if (pumlText && fs.existsSync(pumlText)) {
        pumlText = fs.readFileSync(pumlText, 'utf8');
    }

    if (!pumlText) {
        console.error("Usage: node visualize.cjs <plantuml-text|file-path> [output-path]");
        process.exit(1);
    }

    try {
        await visualize(pumlText, outputPath);
    } catch (err) {
        console.error("Visualization failed:", err.message);
        process.exit(1);
    }
}

main();
