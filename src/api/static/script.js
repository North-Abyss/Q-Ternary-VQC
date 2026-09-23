// --- Theme Settings ---
function toggleDarkMode() {
    const body = document.body;
    const icon = document.getElementById('theme-icon');
    
    if (body.classList.contains('dark-mode')) {
        body.classList.remove('dark-mode');
        icon.textContent = 'dark_mode';
    } else {
        body.classList.add('dark-mode');
        icon.textContent = 'light_mode';
    }
    
    if (batchChart) {
        updateChartTheme();
    }
}

function updateChartTheme() {
    const isDark = document.body.classList.contains('dark-mode');
    const textColor = isDark ? '#e2e2e6' : '#1a1c1e';
    
    batchChart.data.datasets[0].backgroundColor = ['#0061a4', '#ba1a1a'];
    batchChart.options.plugins.legend.labels.color = textColor;
    batchChart.update();
}

// --- Tabs ---
function switchTab(tabId) {
    document.querySelectorAll('.nav-item').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    
    if (tabId === 'single') {
        document.querySelectorAll('.nav-item')[1].classList.add('active');
        document.getElementById('single-tab').classList.add('active');
    } else {
        document.querySelectorAll('.nav-item')[2].classList.add('active');
        document.getElementById('batch-tab').classList.add('active');
    }
}

// --- File Input Display ---
document.getElementById('csv-file').addEventListener('change', function(e) {
    const fileName = e.target.files[0] ? e.target.files[0].name : 'Click to browse or drag CSV here';
    document.getElementById('file-name').textContent = fileName;
});

// --- UI Helpers ---
function showLoading() {
    document.getElementById('result-display').classList.add('hidden');
    document.getElementById('batch-result-display').classList.add('hidden');
    document.getElementById('loading').classList.remove('hidden');
}

function hideLoading() {
    document.getElementById('loading').classList.add('hidden');
}

// --- Single Prediction Submit ---
document.getElementById('prediction-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const inputs = e.target.querySelectorAll('input[type="number"]');
    const features = Array.from(inputs).map(input => parseFloat(input.value));
    
    showLoading();
    
    try {
        const response = await fetch('/predict', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ features: features })
        });
        
        const data = await response.json();
        hideLoading();
        
        if (data.error) {
            alert('Error: ' + data.error);
            return;
        }
        
        displaySingleResult(data.results[0]);
    } catch (err) {
        hideLoading();
        alert('API Request Failed: ' + err.message);
    }
});

function displaySingleResult(result) {
    document.getElementById('result-display').classList.remove('hidden');
    
    const statusIcon = document.querySelector('#pred-status .material-icons-round');
    const statusCircle = document.getElementById('pred-status');
    const statusText = document.getElementById('pred-text');
    const probFill = document.getElementById('prob-fill');
    const probVal = document.getElementById('prob-val');
    
    if (result.quantum_prediction === 1) {
        statusText.textContent = 'MALIGNANT';
        statusText.style.color = 'var(--md-sys-color-error)';
        statusIcon.textContent = 'warning';
        statusCircle.classList.add('malignant');
    } else {
        statusText.textContent = 'BENIGN';
        statusText.style.color = 'var(--md-sys-color-primary)';
        statusIcon.textContent = 'check_circle';
        statusCircle.classList.remove('malignant');
    }
    
    const probPercentage = (result.quantum_probability * 100).toFixed(2);
    probVal.textContent = probPercentage + '%';
    
    setTimeout(() => {
        probFill.style.width = probPercentage + '%';
    }, 100);
}

// --- Batch Prediction Submit ---
let batchChart = null;

document.getElementById('batch-submit').addEventListener('click', async () => {
    const fileInput = document.getElementById('csv-file');
    if (!fileInput.files[0]) {
        alert('Please select a CSV file first.');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', fileInput.files[0]);
    
    showLoading();
    
    try {
        const response = await fetch('/predict', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        hideLoading();
        
        if (data.error) {
            alert('Error: ' + data.error);
            return;
        }
        
        displayBatchResults(data.results);
    } catch (err) {
        hideLoading();
        alert('API Request Failed: ' + err.message);
    }
});

function displayBatchResults(results) {
    document.getElementById('batch-result-display').classList.remove('hidden');
    document.getElementById('batch-count').textContent = results.length;
    
    let benign = 0;
    let malignant = 0;
    
    results.forEach(r => {
        if (r.quantum_prediction === 1) malignant++;
        else benign++;
    });
    
    const ctx = document.getElementById('batchChart').getContext('2d');
    
    if (batchChart) {
        batchChart.destroy();
    }
    
    const isDark = document.body.classList.contains('dark-mode');
    const textColor = isDark ? '#e2e2e6' : '#1a1c1e';
    
    batchChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Benign', 'Malignant'],
            datasets: [{
                data: [benign, malignant],
                backgroundColor: ['#0061a4', '#ba1a1a'],
                borderWidth: 0,
                hoverOffset: 10
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { color: textColor, font: { family: 'Roboto', size: 14 } }
                }
            },
            cutout: '75%',
            animation: {
                animateScale: true,
                animateRotate: true
            }
        }
    });
}
