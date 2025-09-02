// Image preprocessing function
function preprocessImage(imagePath) {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();
    
    img.onload = function() {
      // Set canvas size
      canvas.width = img.width;
      canvas.height = img.height;
      
      // Draw original image
      ctx.drawImage(img, 0, 0);
      
      // Get image data
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const data = imageData.data;
      
      // Convert to grayscale and increase contrast
      for (let i = 0; i < data.length; i += 4) {
        const gray = Math.round(0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2]);
        
        // Increase contrast
        const contrast = 1.5;
        const factor = (259 * (contrast + 255)) / (255 * (259 - contrast));
        const enhanced = Math.max(0, Math.min(255, Math.round(factor * (gray - 128) + 128)));
        
        data[i] = enhanced;     // Red
        data[i + 1] = enhanced; // Green  
        data[i + 2] = enhanced; // Blue
        // Alpha channel remains unchanged
      }
      
      // Put processed image data back
      ctx.putImageData(imageData, 0, 0);
      
      // Convert to blob
      canvas.toBlob(resolve, 'image/png');
    };
    
    img.onerror = reject;
    img.src = imagePath;
  });
}



// Extract Emirates ID data from OCR text (English only)
function extractEmiratesIdData(text) {
  // Filter out Arabic text, keep only English characters, numbers, and basic punctuation
  const englishText = text.replace(/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/g, ' ')
                         .replace(/\s+/g, ' ')
                         .trim();
  
  console.log('=== FILTERED ENGLISH TEXT ===');
  console.log(englishText);
  console.log('=== END FILTERED TEXT ===');
  
  const data = {};
  
  // Extract ID Number (784-XXXX-XXXXXXX-X format)
  const idMatch = englishText.match(/784[-\s]*(\d{4})[-\s]*(\d{7})[-\s]*(\d)/g);
  if (idMatch) {
    data.idNumber = idMatch[0].replace(/\s+/g, '-');
  }
  
  // Extract Name (look for "Name:" pattern)
  const nameMatch = englishText.match(/Name[:\s]*([A-Za-z\s]+?)(?:\s+[A-Z]\s|$)/i);
  if (nameMatch && nameMatch[1]) {
    let name = nameMatch[1].trim();
    // Clean up common OCR artifacts
    name = name.replace(/[^A-Za-z\s]/g, ' ').replace(/\s+/g, ' ').trim();
    if (name.length > 2) {
      data.name = name;
    }
  }
  
  // Extract Date of Birth (DD/MM/YYYY format)
  const dobMatch = englishText.match(/(\d{1,2})\/(\d{1,2})\/(\d{4})/g);
  if (dobMatch && dobMatch.length > 0) {
    // Take the first date that looks like a birth date (not expiry)
    for (const date of dobMatch) {
      const year = parseInt(date.split('/')[2]);
      if (year >= 1950 && year <= 2010) { // Reasonable birth year range
        data.dateOfBirth = date;
        break;
      }
    }
  }
  
  // Extract Expiry Date (usually the latest date)
  if (dobMatch && dobMatch.length > 1) {
    const dates = dobMatch.map(d => {
      const parts = d.split('/');
      return { date: d, year: parseInt(parts[2]) };
    });
    const latestDate = dates.reduce((latest, current) => 
      current.year > latest.year ? current : latest
    );
    if (latestDate.year > 2020) { // Expiry dates are in the future
      data.expiryDate = latestDate.date;
    }
  }
  
  // Extract Card Number
  const cardMatch = englishText.match(/Card Number[\s\/]*([\d]+)/i) || 
                   englishText.match(/(\d{7,8})/g);
  if (cardMatch) {
    data.cardNumber = cardMatch[1] || cardMatch[0];
  }
  
  // Extract Occupation
  const occupationMatch = englishText.match(/Occupation[:\s]*([A-Za-z\s]+?)(?:Employer|$)/i);
  if (occupationMatch && occupationMatch[1]) {
    data.occupation = occupationMatch[1].trim();
  }
  
  // Extract Employer
  const employerMatch = englishText.match(/Employer[:\s]*([A-Za-z\s&\/]+?)(?:$|\n)/i);
  if (employerMatch && employerMatch[1]) {
    data.employer = employerMatch[1].trim();
  }
  
  // Extract Nationality (English only)
  const nationalityMatch = englishText.match(/\b(India|Indian|Pakistan|Pakistani|Bangladesh|Bangladeshi|Philippines|Filipino|Egypt|Egyptian)\b/i);
  if (nationalityMatch) {
    data.nationality = nationalityMatch[1];
  }
  
  return data;
}

// Google ML Kit Text Recognition for webview
window.processImageWithGoogleMLKit = function(imagePath) {
  console.log('Google ML Kit OCR function called with:', imagePath);
  
  return new Promise(async (resolve, reject) => {
    try {
      console.log('=== STARTING GOOGLE ML KIT OCR ===');
      
      // Check if Google ML Kit is available
      if (typeof window.mlkit === 'undefined') {
        console.log('Google ML Kit not available, falling back to Tesseract');
        return fallbackToTesseract(imagePath, resolve, reject);
      }
      
      // Create image element
      const img = new Image();
      img.crossOrigin = 'anonymous';
      
      img.onload = async function() {
        try {
          // Create canvas and get image data
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          canvas.width = img.width;
          canvas.height = img.height;
          ctx.drawImage(img, 0, 0);
          
          // Get image data for ML Kit
          const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
          
          // Use Google ML Kit Text Recognition
          const textRecognizer = new window.mlkit.TextRecognizer();
          const results = await textRecognizer.recognize(imageData);
          
          let extractedText = '';
          if (results && results.blocks) {
            for (const block of results.blocks) {
              if (block.lines) {
                for (const line of block.lines) {
                  if (line.text) {
                    extractedText += line.text + '\n';
                  }
                }
              }
            }
          }
          
          console.log('=== GOOGLE ML KIT RAW TEXT ===');
          console.log(extractedText);
          console.log('=== END RAW TEXT ===');
          
          // Filter to English only and clean up
          const cleanText = extractedText
            .replace(/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
          
          console.log('=== CLEANED ML KIT TEXT ===');
          console.log(cleanText);
          console.log('=== END CLEANED TEXT ===');
          
          resolve(cleanText);
          
        } catch (mlkitError) {
          console.error('Google ML Kit processing failed:', mlkitError);
          // Fallback to Tesseract
          fallbackToTesseract(imagePath, resolve, reject);
        }
      };
      
      img.onerror = function() {
        console.error('Failed to load image for ML Kit');
        fallbackToTesseract(imagePath, resolve, reject);
      };
      
      img.src = imagePath;
      
    } catch (error) {
      console.error('Google ML Kit setup failed:', error);
      fallbackToTesseract(imagePath, resolve, reject);
    }
  });
};

// Fallback to Tesseract OCR
function fallbackToTesseract(imagePath, resolve, reject) {
  console.log('=== FALLBACK TO TESSERACT OCR ===');
  
  if (typeof Tesseract === 'undefined') {
    console.error('Neither Google ML Kit nor Tesseract available');
    resolve('');
    return;
  }
  
  Tesseract.recognize(
    imagePath,
    'eng',
    {
      logger: m => {
        if (m.status === 'recognizing text') {
          console.log(`Tesseract Progress: ${Math.round(m.progress * 100)}%`);
        }
      }
    }
  ).then(({ data: { text } }) => {
    console.log('=== TESSERACT FALLBACK TEXT ===');
    console.log(text);
    
    const cleanText = text
      .replace(/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    
    resolve(cleanText);
  }).catch(error => {
    console.error('Tesseract fallback failed:', error);
    resolve('');
  });
}

// Keep backward compatibility
window.processImageWithMLKit = window.processImageWithGoogleMLKit;