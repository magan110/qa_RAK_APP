// Simple bridge that loads Tesseract.js and exposes runTesseract(dataUrl)
// Usage: window.runTesseract(dataUrl).then(text => ...)
(function(){
  if (window.runTesseract) return;
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/tesseract.js@4/dist/tesseract.min.js';
  script.onload = () => {
    console.log('tesseract.js loaded');
    window.runTesseract = function(dataUrl) {
      return new Promise(function(resolve, reject) {
        try {
          Tesseract.recognize(dataUrl, 'eng')
            .then(function(result){
              resolve(result.data.text);
            })
            .catch(function(err){
              reject(err && err.message ? err.message : err);
            });
        } catch (e) { reject(e && e.message ? e.message : e); }
      });
    };
  };
  script.onerror = function(e){ console.error('Failed to load tesseract.js', e); };
  document.head.appendChild(script);
})();
