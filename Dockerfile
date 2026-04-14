# Use the official rocker/shiny image as a base
# This includes R, Shiny Server, and several base utilities
FROM rocker/shiny:4.3.1

# Install system dependencies required by R packages like leaflet, tidyverse, and plotly
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libxt-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
# Using the fixed CRAN snapshot ensures reproducibility across different machines
RUN R -e "install.packages(c('shinydashboard', 'tidyverse', 'leaflet', 'DT', 'plotly'), repos='https://cran.rstudio.com/')"

# Clean the default shiny-server directory and copy your app files
RUN rm -rf /srv/shiny-server/*
COPY GAS_app.R /srv/shiny-server/
COPY Example_GAS_Genomic_Data.csv /srv/shiny-server/

# Set the working directory
WORKDIR /srv/shiny-server/

# Expose port 3838 (the default for Shiny Server)
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
