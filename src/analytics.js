const GA_ID = 'UA-158623770-1'

window.dataLayer = window.dataLayer || []
function ga(){dataLayer.push(arguments)}
ga('js', new Date())
ga('config', GA_ID, {anonymize_ip: true})

export default function connect(app) {
  app.ports.urlChange.subscribe(({path}) => {
    // console.log('urlChange', url)
    ga('config', GA_ID, {'page-path': path})
  })
}
