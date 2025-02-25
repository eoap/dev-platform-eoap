from setuptools import setup

console_scripts = ["stage-out=app.main:main"]

setup(
    name="stage-out",
    version="0.1",
    description="The funniest joke in the world",
    packages=["app"],
    entry_points={"console_scripts": console_scripts},
    zip_safe=False,
)
