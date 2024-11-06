# Can't use python 3.12 cause something breaks
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tk \
    git \
    g++ \
    procps \
    && rm -rf /var/lib/apt/lists/*


# Install dependencies
RUN pip install py-spy matplotlib shapely numpy scipy certifi setuptools

# Install miniball using the already downloaded version
COPY ./miniball /tmp/miniball
WORKDIR /tmp/miniball/python
RUN python setup.py install

# Clean up temporary files after installation
RUN rm -rf /tmp/miniball

# Copy project files into the container
WORKDIR /app
COPY . /app

# Default command
CMD ["python", "main.py", "-d", "15", "-p", "8", "-rq", "requests/group_8/hard.json", "-ng"]
