const zlib = require('zlib');

const PUML = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_';
const B64 =  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

const map = {};
for (let i = 0; i < B64.length; i++) {
    map[B64[i]] = PUML[i];
}

/**
 * Encodes a PlantUML string into the format required for the server URL.
 */
function encode(text) {
    const utf8 = Buffer.from(text, 'utf8');
    const deflated = zlib.deflateRawSync(utf8, { level: 9 });
    
    const b64url = deflated.toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');
    
    let res = "";
    for (const char of b64url) {
        res += map[char] || char;
    }
    return res;
}

if (require.main === module) {
    const input = process.argv[2];
    if (!input) {
        process.exit(1);
    }
    console.log(encode(input));
}

module.exports = { encode };
