from setuptools import setup, find_packages

setup(
    name="medinovai-stream-bus",
    version="1.0.0",
    packages=find_packages(),
    install_requires=["httpx>=0.26.0"],
    python_requires=">=3.9",
)
