import csv
import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from selenium.webdriver.chrome.options import Options
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('scraper.log'),
        logging.StreamHandler()
    ]
)

class LinkedInScraper:

    def __init__(self, email, password):
        self.email = email
        self.password = password
        self.driver = None
        self.profiles_data = []

    def setup_driver(self):
        chrome_options = Options()

        chrome_options.add_argument('--disable-blink-features=AutomationControlled')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--start-maximized')

        user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        ]

        chrome_options.add_argument(f'user-agent={random.choice(user_agents)}')

        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)

        self.driver = webdriver.Chrome(options=chrome_options)

        self.driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

        logging.info("Chrome driver initialized successfully")

    def login(self):
        try:
            logging.info("Attempting to log in to LinkedIn...")
            self.driver.get('https://www.linkedin.com/login')

            time.sleep(random.uniform(2, 4))

            email_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.ID, "username"))
            )
            email_field.send_keys(self.email)

            password_field = self.driver.find_element(By.ID, "password")
            password_field.send_keys(self.password)

            time.sleep(random.uniform(1, 2))

            login_button = self.driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            login_button.click()

            time.sleep(random.uniform(5, 7))

            if "feed" in self.driver.current_url or "mynetwork" in self.driver.current_url:
                logging.info("Successfully logged in to LinkedIn")
                return True
            else:
                logging.error("Login failed - might need verification")
                return False

        except Exception as e:
            logging.error(f"Error during login: {str(e)}")
            return False

    def extract_profile_data(self, profile_url):
        try:
            logging.info(f"Scraping profile: {profile_url}")

            self.driver.get(profile_url)

            time.sleep(random.uniform(3, 5))

            self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2);")
            time.sleep(random.uniform(2, 3))

            profile_data = {
                'profile_url': profile_url,
                'name': '',
                'headline': '',
                'location': '',
                'about': '',
                'status': 'success'
            }

            try:
                h1_elements = self.driver.find_elements(By.TAG_NAME, "h1")
                for h1 in h1_elements:
                    name_text = h1.text.strip()
                    if name_text and 2 <= len(name_text) <= 100 and not name_text.startswith('http'):
                        profile_data['name'] = name_text
                        logging.info(f"Found name: {name_text}")
                        break

                if not profile_data['name']:
                    logging.warning(f"Could not extract name from {profile_url}")
            except Exception as e:
                logging.warning(f"Error extracting name: {str(e)}")

            try:
                headline_element = self.driver.find_element(By.CSS_SELECTOR, "div.text-body-medium")
                profile_data['headline'] = headline_element.text.strip()
            except:
                logging.warning(f"Could not extract headline from {profile_url}")

            try:
                location_element = self.driver.find_element(By.CSS_SELECTOR, "span.text-body-small.inline.t-black--light.break-words")
                profile_data['location'] = location_element.text.strip()
            except:
                logging.warning(f"Could not extract location from {profile_url}")

            try:
                about_button = self.driver.find_element(By.ID, "about")
                self.driver.execute_script("arguments[0].scrollIntoView(true);", about_button)
                time.sleep(1)
                about_section = self.driver.find_element(By.CSS_SELECTOR, "section.artdeco-card div.display-flex.ph5.pv3")
                about_text = about_section.find_element(By.TAG_NAME, "span")
                profile_data['about'] = about_text.text.strip()[:500]
            except:
                logging.warning(f"Could not extract about section from {profile_url}")

            logging.info(f"Successfully scraped: {profile_data['name']}")
            return profile_data

        except TimeoutException:
            logging.error(f"Timeout while loading profile: {profile_url}")
            return {
                'profile_url': profile_url,
                'name': '',
                'headline': '',
                'location': '',
                'about': '',
                'status': 'timeout'
            }
        except Exception as e:
            logging.error(f"Error scraping {profile_url}: {str(e)}")
            return {
                'profile_url': profile_url,
                'name': '',
                'headline': '',
                'location': '',
                'about': '',
                'status': f'error: {str(e)}'
            }

    def scrape_profiles(self, profile_urls):
        total = len(profile_urls)
        success_count = 0

        for idx, url in enumerate(profile_urls, 1):
            logging.info(f"Processing profile {idx}/{total}")

            if idx > 1:
                delay = random.uniform(5, 10)
                logging.info(f"Waiting {delay:.2f} seconds before next profile...")
                time.sleep(delay)

            profile_data = self.extract_profile_data(url)
            self.profiles_data.append(profile_data)

            if profile_data['status'] == 'success':
                success_count += 1

        logging.info(f"Scraping completed: {success_count}/{total} profiles successful")

    def save_to_csv(self, filename='linkedin_profiles.csv'):
        if not self.profiles_data:
            logging.warning("No data to save")
            return

        try:
            with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
                fieldnames = ['profile_url', 'name', 'headline', 'location', 'about', 'status']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

                writer.writeheader()
                for profile in self.profiles_data:
                    writer.writerow(profile)

            logging.info(f"Data saved to {filename}")
            print(f"\n✓ Successfully saved {len(self.profiles_data)} profiles to {filename}")

        except Exception as e:
            logging.error(f"Error saving to CSV: {str(e)}")

    def close(self):
        if self.driver:
            self.driver.quit()
            logging.info("Browser closed")


def main():

    print("=" * 60)
    print("LinkedIn Profile Scraper")
    print("=" * 60)

    email = input("\nEnter your LinkedIn email: ").strip()
    password = input("Enter your LinkedIn password: ").strip()

    profile_urls = [
        "https://www.linkedin.com/in/satyanadella/",
        "https://www.linkedin.com/in/sundar-pichai-4b2ba418b/",
        "https://www.linkedin.com/in/jeffweiner08/",
        "https://www.linkedin.com/in/williamhgates/",
        "https://www.linkedin.com/in/reed-hastings-10a77b/",
    ]

    load_from_file = input("\nLoad profile URLs from file? (y/n): ").strip().lower()
    if load_from_file == 'y':
        filename = input("Enter filename (e.g., urls.txt): ").strip()
        try:
            with open(filename, 'r') as f:
                profile_urls = [line.strip() for line in f if line.strip()]
            print(f"Loaded {len(profile_urls)} URLs from {filename}")
        except FileNotFoundError:
            print(f"File {filename} not found. Using default URLs.")

    print(f"\nPreparing to scrape {len(profile_urls)} profiles...")

    scraper = LinkedInScraper(email, password)

    try:
        scraper.setup_driver()

        if not scraper.login():
            print("\n✗ Login failed. Please check your credentials.")
            return

        print("\n✓ Login successful! Starting to scrape profiles...\n")

        scraper.scrape_profiles(profile_urls)

        scraper.save_to_csv()

        print("\n" + "=" * 60)
        print("Scraping completed successfully!")
        print("=" * 60)

    except KeyboardInterrupt:
        print("\n\nScraping interrupted by user")
        scraper.save_to_csv('linkedin_profiles_partial.csv')
    except Exception as e:
        logging.error(f"An error occurred: {str(e)}")
        print(f"\n✗ Error: {str(e)}")
    finally:
        scraper.close()


if __name__ == "__main__":
    main()
