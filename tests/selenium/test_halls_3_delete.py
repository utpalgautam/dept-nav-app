import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_delete_hall_lab(driver, base_url):
    """Test Case: Delete the previously added/edited lab."""
    driver.get(f"{base_url}/halls-labs")
    
    wait = WebDriverWait(driver, 10)
    
    # 1. Search for the lab
    time.sleep(1)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    time.sleep(0.5)
    search_input.send_keys("Selenium Test Lab")
    time.sleep(1) # Wait for search to filter
    
    # 2. Click the Delete icon
    delete_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//div[contains(@class, 'hl-table-row') and .//div[text()='Selenium Test Lab']]//button[contains(@class, 'hl-action-icon')]")))
    time.sleep(1)
    delete_btn.click()
    
    # 3. Handle the confirmation alert
    time.sleep(1)
    alert = wait.until(EC.alert_is_present())
    alert.accept()
    
    # 4. Verify the lab is deleted (wait for it to disappear)
    time.sleep(2)
    # The name should no longer be present in the table
    wait.until(EC.invisibility_of_element_located((By.XPATH, f"//div[text()='Selenium Test Lab']")))
    
    print("Lab deleted successfully.")
    time.sleep(2)
