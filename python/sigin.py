 #-*-coding:utf-8-*-

from selenium import webdriver  
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from fake_useragent import UserAgent
import os
from datetime import datetime, date
import time

username = 'username'  
password = 'password' 
login_url = 'login_url'  
checkin_url = 'checkin_url'  

now = datetime.now() # current date and time
names = now.strftime("%Y-%m-%d-%H")
years =  now.strftime("%Y")
mmonths =  now.strftime("%m")
hs = now.hour

saveLocalationAndName = str(years) + '/' + str(mmonths) + '/' + names + '.png'

options = webdriver.FirefoxOptions()
#UserAgent(use_cache_server=False).random
options.set_preference("general.useragent.override", UserAgent(use_cache_server=False).random)
#options.update_preferences()
options.add_argument('-headless')  
driver = webdriver.Firefox(executable_path='geckodriver', options=options)
try:
    driver.get(login_url)
except:
    pass
    print("Open login_url check")
time.sleep(2)

driver.set_window_size(1920,1080)

driver.find_element_by_id('login').send_keys(username)  
driver.find_element_by_id('password').send_keys(password)

login_btn = driver.find_element_by_xpath("//input[@name='className']")
login_btn.click()

time.sleep(2)
try:
    driver.get(checkin_url)
except:
    pass
    print("Open checkin_url check")

time.sleep(1)

try: 
    if('23' == str(hs) ):
        driver.find_element_by_xpath("//*[@class='className']").click() 
        driver.save_screenshot(saveLocalationAndName)
        print("Success")
    else:
        driver.find_element_by_xpath("//*[@class='className']").click()
        print("Already sigin")
except:
    pass
    print("Sigin Check")
  


agent = driver.execute_script("return navigator.userAgent")
print('agent = ',agent)
driver.close()
