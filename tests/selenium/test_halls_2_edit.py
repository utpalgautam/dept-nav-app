import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys

def test_edit_hall_lab(driver, base_url):
    """Test Case: Edit an existing lab."""
    driver.get(f"{base_url}/halls-labs")
    
    wait = WebDriverWait(driver, 10)
    
    # 1. Search for the lab
    time.sleep(1)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    time.sleep(0.5)
    search_input.send_keys("Selenium Test Lab")
    time.sleep(1) # Wait for search to filter
    
    # 2. Click "Modify"
    edit_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//div[contains(@class, 'hl-table-row') and .//div[text()='Selenium Test Lab']]//button[contains(text(), 'Modify')]")))
    time.sleep(1)
    edit_btn.click()
    
    # 3. Update Capacity and Department
    time.sleep(1)
    capacity_input = wait.until(EC.presence_of_element_located((By.NAME, "capacity")))
    capacity_input.click()
    capacity_input.send_keys(Keys.CONTROL + "a")
    capacity_input.send_keys(Keys.BACKSPACE)
    capacity_input.send_keys("50")
    
    time.sleep(0.5)
    dept_input = driver.find_element(By.NAME, "department")
    dept_input.click()
    dept_input.send_keys(Keys.CONTROL + "a")
    dept_input.send_keys(Keys.BACKSPACE)
    dept_input.send_keys("Advanced QA Engineering")
    
    # 4. Save the changes
    time.sleep(1)
    submit_btn = driver.find_element(By.XPATH, "//button[contains(@class, 'hl-btn-save')]")
    submit_btn.click()
    
    # 5. Verify the update (search for it again and check)
    time.sleep(2)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    search_input.send_keys("Selenium Test Lab")
    time.sleep(1)
    
    wait.until(EC.presence_of_element_located((By.XPATH, f"//div[text()='Advanced QA Engineering']")))
    
    print("Lab edited successfully.")
    time.sleep(2)
