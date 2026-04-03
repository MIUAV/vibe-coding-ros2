from setuptools import setup

package_name = 'py_subscriber'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/' + package_name]),
        ('share/' + package_name + '/launch', ['launch/py_subscriber.launch.py']),
    ],
    install_scripts=['src/py_subscriber_node.py'],
    entry_points={
        'console_scripts': [
            'py_subscriber = py_subscriber.py_subscriber_node:main',
        ],
    },
    zip_safe=False,
    maintainer='MIUAV Dev',
    maintainer_email='dev@miuav.com',
    description='ROS2 Python 订阅者示例节点',
    license='Apache-2.0',
)
