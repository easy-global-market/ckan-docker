from setuptools import setup

setup(
    name='ckanext-custom-emails',
    version='0.1.0',
    packages=['ckanext.custom_emails'],
    namespace_packages=['ckanext'],
    install_requires=[],
    entry_points='''
        [ckan.plugins]
        custom_emails = ckanext.custom_emails.plugin:CustomEmailsPlugin
    ''',
)