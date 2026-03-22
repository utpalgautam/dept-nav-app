import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

@pytest.fixture(scope="function")
def driver():
    """Fixture to set up and tear down the Selenium WebDriver."""
    chrome_options = Options()
    # Uncomment the next line to run in headless mode
    # chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=1920,1080")
    
    # Using ChromeDriverManager to handle driver installation
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    driver.implicitly_wait(10)  # Standard implicit wait
    yield driver
    driver.quit()

@pytest.fixture
def base_url():
    """Fixture for the application's base URL."""
    return "http://localhost:3000"
