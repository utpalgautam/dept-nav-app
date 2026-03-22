import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select

def test_add_hall_lab(driver, base_url):
    """Test Case: Add a new lab."""
    driver.get(f"{base_url}/halls-labs")
    
    wait = WebDriverWait(driver, 10)
    add_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Add Hall/Lab')]")))
    
    time.sleep(1)  # Delay for visual clarity
    add_btn.click()
    
    # Select "Add New Lab"
    time.sleep(1)
    lab_toggle = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Add New Lab')]")))
    lab_toggle.click()
    
    # Fill in the form
    time.sleep(1)
    driver.find_element(By.NAME, "name").send_keys("Selenium Test Lab")
    
    # Select a building
    time.sleep(0.5)
    building_select = Select(driver.find_element(By.NAME, "building"))
    options = building_select.options
    if len(options) > 1:
        building_select.select_by_index(1)
        
    time.sleep(0.5)
    driver.find_element(By.NAME, "floor").send_keys("2")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "capacity").send_keys("30")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "department").send_keys("Computer Science & Engineering")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "incharge").send_keys("Dr. Selenium Runner")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "inchargeEmail").send_keys("runner@selenium.edu")
    
    # Submit the form
    time.sleep(1)
    submit_btn = driver.find_element(By.XPATH, "//button[contains(@class, 'hl-btn-save')]")
    submit_btn.click()
    
    # Verify the lab was added
    time.sleep(2)
    # Search for it to confirm
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    search_input.send_keys("Selenium Test Lab")
    time.sleep(1)
    
    wait.until(EC.presence_of_element_located((By.XPATH, f"//div[text()='Selenium Test Lab']")))
    
    print("Lab added successfully.")
    time.sleep(2)
