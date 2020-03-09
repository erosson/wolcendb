const fs = require('fs').promises

main()
async function main() {
  const revs = (await stdin())
    .split(/\s+/)
    .filter(s => s !== '' && s !== 'PRE')
    .map(s => s.replace(/\/$/, ''))
  console.log(JSON.stringify(revs))
}
async function stdin() {
  // https://stackoverflow.com/a/54565854
  const chunks = []
  for await (const chunk of process.stdin) {
    chunks.push(chunk)
  }
  return Buffer.concat(chunks).toString()
}
