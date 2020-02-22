const GA_ID = 'UA-158623770-1'

window.dataLayer = window.dataLayer || []
function gtag(){dataLayer.push(arguments)}
gtag('js', new Date())
gtag('config', GA_ID, {anonymize_ip: true})

export default function connect(app) {
  app.ports.urlChange.subscribe(({path}) => {
    // https://developers.google.com/analytics/devguides/collection/gtagjs/pages
    gtag('config', GA_ID, {
      // page_path: path,
      page_location: document.location.href,
    })
  })
}
