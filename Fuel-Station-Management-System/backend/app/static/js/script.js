// DOM Elements
const sidebar = document.querySelector('.sidebar');
const sidebarToggle = document.querySelector('.sidebar-toggle');
const searchInput = document.querySelector('.search-bar input');
const notifications = document.querySelector('.notifications');
const userProfile = document.querySelector('.user-profile');

document.addEventListener("DOMContentLoaded", function () {
    const toggleBtn = document.querySelector('.sidebar-toggle');
    const sidebar = document.querySelector('.sidebar');
    const toggleIcon = toggleBtn.querySelector('i');

    toggleBtn.addEventListener('click', function () {
        sidebar.classList.toggle('collapsed');
    });
});



// Search functionality
searchInput.addEventListener('input', (e) => {
    const searchTerm = e.target.value.toLowerCase();
    // Add search logic here
    console.log('Searching for:', searchTerm);
});

// Notifications dropdown
notifications.addEventListener('click', (e) => {
    e.stopPropagation();
    // Toggle notifications dropdown
    console.log('Show notifications');
});

// User profile dropdown
userProfile.addEventListener('click', (e) => {
    e.stopPropagation();
    // Toggle user profile dropdown
    console.log('Show user profile dropdown');
});

// Close dropdowns when clicking anywhere
document.addEventListener('click', () => {
    // Close all dropdowns
    console.log('Close all dropdowns');
});

// Sample data for charts (using Chart.js)
function initializeCharts() {
    // Sales Chart
    const salesCtx = document.getElementById('salesChart')?.getContext('2d');
    if (salesCtx) {
        new Chart(salesCtx, {
            type: 'line',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                datasets: [{
                    label: 'Monthly Sales',
                    data: [65000, 59000, 80000, 81000, 56000, 72000],
                    borderColor: '#4361ee',
                    tension: 0.3,
                    fill: true,
                    backgroundColor: 'rgba(67, 97, 238, 0.1)'
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            drawBorder: false
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        }
                    }
                }
            }
        });
    }


    // Fuel Level Chart
    const fuelCtx = document.getElementById('fuelChart')?.getContext('2d');
    if (fuelCtx) {
        new Chart(fuelCtx, {
            type: 'doughnut',
            data: {
                labels: ['Petrol', 'Diesel', 'CNG'],
                datasets: [{
                    data: [45, 30, 25],
                    backgroundColor: [
                        '#4361ee',
                        '#4cc9f0',
                        '#7209b7'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }
}

// Initialize charts when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    initializeCharts();
    
    // Add active class to current nav item
    const currentPage = window.location.hash || '#dashboard';
    const navLinks = document.querySelectorAll('.sidebar nav a');
    
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPage) {
            link.parentElement.classList.add('active');
        }
    });
});

// Form validation for login/register
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return false;
    
    const inputs = form.querySelectorAll('input[required]');
    let isValid = true;
    
    inputs.forEach(input => {
        if (!input.value.trim()) {
            isValid = false;
            input.classList.add('error');
        } else {
            input.classList.remove('error');
        }
    });
    
    return isValid;
}

// Sample function to show toast notifications
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(toast);
        }, 300);
    }, 3000);
}

// Example usage:
// showToast('Login successful!', 'success');
// showToast('Error: Please check your input', 'error');
