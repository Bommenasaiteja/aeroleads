import streamlit as st
import pandas as pd
import time
from datetime import datetime
import io
import sys
from linkedin_scraper import LinkedInScraper
import logging
from io import StringIO

st.set_page_config(
    page_title="LinkedIn Profile Scraper",
    page_icon="🔍",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.markdown("""
    <style>
    .main {
        padding: 0rem 0rem;
    }
    .stProgress > div > div > div > div {
        background-color: #0077b5;
    }
    .log-container {
        background-color: #1e1e1e;
        color: #ffffff;
        padding: 20px;
        border-radius: 10px;
        font-family: 'Courier New', monospace;
        font-size: 12px;
        height: 400px;
        overflow-y: scroll;
    }
    .success-box {
        padding: 20px;
        background-color: #d4edda;
        border-left: 5px solid #28a745;
        border-radius: 5px;
        margin: 10px 0;
    }
    .error-box {
        padding: 20px;
        background-color: #f8d7da;
        border-left: 5px solid #dc3545;
        border-radius: 5px;
        margin: 10px 0;
    }
    .info-box {
        padding: 20px;
        background-color: #d1ecf1;
        border-left: 5px solid #0c5460;
        border-radius: 5px;
        margin: 10px 0;
    }
    </style>
    """, unsafe_allow_html=True)

if 'scraping' not in st.session_state:
    st.session_state.scraping = False
if 'results' not in st.session_state:
    st.session_state.results = None
if 'logs' not in st.session_state:
    st.session_state.logs = []

class StreamlitLogHandler(logging.Handler):
    def __init__(self):
        super().__init__()

    def emit(self, record):
        log_entry = self.format(record)
        st.session_state.logs.append(log_entry)

st.title("🔍 LinkedIn Profile Scraper")
st.markdown("### Extract profile data from LinkedIn with ease")
st.markdown("---")

with st.sidebar:
    st.header("⚙️ Settings")

    st.markdown("### LinkedIn Credentials")
    email = st.text_input("Email", type="default", key="email")
    password = st.text_input("Password", type="password", key="password")

    st.markdown("---")

    st.markdown("### ℹ️ About")
    st.info("""
    **Features:**
    - Upload file or paste URLs
    - Real-time progress tracking
    - Live logs display
    - Download results as CSV
    - Beautiful interface

    **Extracts:**
    - Name, Headline, Location
    - About section
    """)

    st.markdown("---")
    st.markdown("### 📊 Stats")
    if st.session_state.results:
        df = st.session_state.results
        success_count = len(df[df['status'] == 'success'])
        total_count = len(df)
        st.metric("Success Rate", f"{(success_count/total_count)*100:.1f}%")
        st.metric("Total Profiles", total_count)
        st.metric("Successful", success_count)

col1, col2 = st.columns([2, 1])

with col1:
    st.markdown("## 📝 Input LinkedIn Profile URLs")

    input_method = st.radio(
        "Choose input method:",
        ["📄 Upload File", "✍️ Paste URLs"],
        horizontal=True
    )

    profile_urls = []

    if input_method == "📄 Upload File":
        uploaded_file = st.file_uploader(
            "Upload a text file with LinkedIn URLs (one per line)",
            type=['txt'],
            help="Each line should contain one LinkedIn profile URL"
        )

        if uploaded_file:
            content = uploaded_file.read().decode('utf-8')
            profile_urls = [line.strip() for line in content.split('\n') if line.strip()]
            st.success(f"✅ Loaded {len(profile_urls)} URLs from file")

            with st.expander("📋 Preview URLs"):
                for idx, url in enumerate(profile_urls[:10], 1):
                    st.text(f"{idx}. {url}")
                if len(profile_urls) > 10:
                    st.text(f"... and {len(profile_urls) - 10} more")

    else:
        urls_text = st.text_area(
            "Paste LinkedIn profile URLs (one per line):",
            height=200,
            placeholder="https://www.linkedin.com/in/username1/\nhttps://www.linkedin.com/in/username2/\nhttps://www.linkedin.com/in/username3/"
        )

        if urls_text:
            profile_urls = [line.strip() for line in urls_text.split('\n') if line.strip()]
            st.success(f"✅ Found {len(profile_urls)} URLs")

with col2:
    st.markdown("## 🎯 Quick Actions")

    if st.button("📌 Load Sample URLs", use_container_width=True):
        sample_urls = """https://www.linkedin.com/in/satyanadella/
https://www.linkedin.com/in/sundar-pichai-4b2ba418b/
https://www.linkedin.com/in/jeffweiner08/
https://www.linkedin.com/in/williamhgates/
https://www.linkedin.com/in/reed-hastings-10a77b/"""
        st.session_state.sample_urls = sample_urls
        st.rerun()

    st.markdown("---")

    if st.button("🗑️ Clear All", use_container_width=True):
        st.session_state.results = None
        st.session_state.logs = []
        st.rerun()

st.markdown("---")

if profile_urls:
    st.markdown("## 🚀 Ready to Scrape")

    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("URLs to Scrape", len(profile_urls))
    with col2:
        estimated_time = len(profile_urls) * 45
        st.metric("Estimated Time", f"{estimated_time//60} min {estimated_time%60} sec")
    with col3:
        st.metric("Status", "Ready ✅")

    st.markdown("---")

    if st.button("🎬 Start Scraping", type="primary", use_container_width=True, disabled=st.session_state.scraping):

        if not email or not password:
            st.error("⚠️ Please enter your LinkedIn credentials in the sidebar!")
        else:
            st.session_state.scraping = True
            st.session_state.logs = []

            log_handler = StreamlitLogHandler()
            log_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
            logger = logging.getLogger()
            logger.addHandler(log_handler)
            logger.setLevel(logging.INFO)

            progress_container = st.container()
            log_container = st.container()

            with progress_container:
                progress_bar = st.progress(0)
                status_text = st.empty()
                current_profile = st.empty()

            with log_container:
                st.markdown("### 📊 Live Logs")
                log_display = st.empty()

            try:
                status_text.text("🔧 Initializing scraper...")
                scraper = LinkedInScraper(email, password)

                status_text.text("🌐 Setting up browser...")
                scraper.setup_driver()

                status_text.text("🔐 Logging in to LinkedIn...")
                if not scraper.login():
                    st.error("❌ Login failed! Please check your credentials.")
                    st.session_state.scraping = False
                    st.stop()

                st.success("✅ Login successful!")

                results = []
                total = len(profile_urls)

                for idx, url in enumerate(profile_urls):
                    progress = (idx + 1) / total
                    progress_bar.progress(progress)
                    status_text.text(f"📍 Scraping profile {idx + 1} of {total}")
                    current_profile.markdown(f"**Current:** {url}")

                    if st.session_state.logs:
                        log_html = "<div class='log-container'>"
                        for log in st.session_state.logs[-20:]:
                            log_html += f"<div>{log}</div>"
                        log_html += "</div>"
                        log_display.markdown(log_html, unsafe_allow_html=True)

                    if idx > 0:
                        time.sleep(5)

                    profile_data = scraper.extract_profile_data(url)
                    results.append(profile_data)

                scraper.close()

                df = pd.DataFrame(results)
                st.session_state.results = df
                st.session_state.scraping = False

                progress_bar.progress(1.0)
                status_text.text("✅ Scraping completed!")

                st.success(f"🎉 Successfully scraped {len(results)} profiles!")
                st.balloons()

            except Exception as e:
                st.error(f"❌ Error: {str(e)}")
                st.session_state.scraping = False
                if 'scraper' in locals():
                    scraper.close()

if st.session_state.results is not None:
    st.markdown("---")
    st.markdown("## 📊 Results")

    df = st.session_state.results

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Profiles", len(df))
    with col2:
        success_count = len(df[df['status'] == 'success'])
        st.metric("Successful", success_count, delta=f"{(success_count/len(df))*100:.1f}%")
    with col3:
        failed_count = len(df[df['status'] != 'success'])
        st.metric("Failed", failed_count)
    with col4:
        with_name = len(df[df['name'] != ''])
        st.metric("With Name", with_name)

    st.markdown("---")

    st.markdown("### 📋 Scraped Data")

    col1, col2 = st.columns(2)
    with col1:
        status_filter = st.multiselect(
            "Filter by Status",
            options=df['status'].unique(),
            default=df['status'].unique()
        )
    with col2:
        search_term = st.text_input("🔍 Search in results", "")

    filtered_df = df[df['status'].isin(status_filter)]
    if search_term:
        filtered_df = filtered_df[
            filtered_df.apply(lambda row: search_term.lower() in str(row).lower(), axis=1)
        ]

    st.dataframe(
        filtered_df,
        use_container_width=True,
        height=400
    )

    st.markdown("---")

    st.markdown("### 💾 Download Results")

    col1, col2 = st.columns(2)

    with col1:
        csv = df.to_csv(index=False)
        st.download_button(
            label="📥 Download as CSV",
            data=csv,
            file_name=f"linkedin_profiles_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
            mime="text/csv",
            use_container_width=True
        )

    with col2:
        buffer = io.BytesIO()
        with pd.ExcelWriter(buffer, engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name='LinkedIn Profiles')

        st.download_button(
            label="📥 Download as Excel",
            data=buffer.getvalue(),
            file_name=f"linkedin_profiles_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx",
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            use_container_width=True
        )

st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #666;'>
    <p>LinkedIn Profile Scraper | Made with Streamlit</p>
</div>
""", unsafe_allow_html=True)
