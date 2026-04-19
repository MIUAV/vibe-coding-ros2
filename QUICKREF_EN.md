# QUICKREF.md — ROS2 Command Quick Lookup
> A quick look at the most commonly used commands for daily development.Sort by scenario.
---
# # Environment Initialization

```bash
source /opt/ros/humble/setup.bash      # ROS2 Humble
source /opt/ros/iron/setup.bash        # ROS2 Iron
source /opt/ros/jazzy/setup.bash       # ROS2 Jazzy
source install/setup.bash               # workspace

echo "ROS_DISTRO: $ROS_DISTRO"
ros2 doctor --check-deps               # check dependencies
```
---
Package Manager

```bash
ros2 pkg create --pkg-name MY_PKG --node-name my_node   # create package
ros2 pkg list                          # list all packages
ros2 pkg executables                   # list all executables
ros2 pkg prefix MY_PKG                # package path
ros2 pkg xml MY_PKG                   # package manifest XML
```
---
compiled

```bash
colcon build                           # full build
colcon build --packages-select PKG    # single package build
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release  # Release mode
colcon build --symlink-install         # symlink install (no rebuild on code change)
colcon build --event-handlers console_direct+  # show build output

make -C build/MY_PKG                  # incremental build
```
---
# # Run Node

```bash
ros2 run MY_PKG my_node                # run node
ros2 run MY_PKG my_node --ros-args -p param:=value  # with parameters


ros2 lifecycle set /my_node configure  # configure
ros2 lifecycle set /my_node activate   # activate
ros2 lifecycle list /my_node          # view state machine
```
---
Topic

```bash
ros2 topic list                        # list all topics
ros2 topic echo /chatter --pdf         # view message (--pdf format)
ros2 topic hz /chatter                 # frequency
ros2 topic bw /chatter                 # bandwidth
ros2 topic delay /chatter              # latency
ros2 topic pub /chatter std_msgs/msg/String "{data: 'hello'}"  # publish
ros2 topic info /chatter               # view topic type
ros2 run rqt_graph rqt_graph           # visualize computation graph
```
---
# # Service/Action

```bash
ros2 service list                      # list services
ros2 service call /add_two_ints std_srvs/srv/Empty "{}"  # call
ros2 service type /add_two_ints        # service type

ros2 action list                       # list actions
ros2 action send_goal /fibonacci action_tutorials_interfaces/action/Fibonacci "{order: 5}"
ros2 action send_goal /fibonacci action_tutorials_interfaces/action/Fibonacci "{order: 5}" --feedback  # with feedback
```
---
Specs

```bash
ros2 param list                         # list parameters
ros2 param get /my_node my_param        # get parameter
ros2 param set /my_node my_param 42     # set parameter
ros2 param dump /my_node                # dump parameters
ros2 param load /my_node.yaml           # load parameters

ros2 run rqt_reconfigure rqt_reconfigure  # dynamic reconfigure GUI
```
---
# # Launch

```bash
ros2 launch my_pkg my_launch.py        # launch file
ros2 launch my_pkg my_launch.py -s     # silent mode


ros2 launch pkg1 launch1.py pkg2:=pkg2_launch2:=launch2.py
```
---
# # Bag Recording Playback

```bash
ros2 bag record /chatter /odom        # record (specific topics)
ros2 bag record -a                      # record all
ros2 bag play bag_name                  # playback
ros2 bag info bag_name                  # view info
ros2 bag compress bag_name -c zstd      # compress
```
---
Status Monitoring

```bash
ros2 node list                          # list running nodes
ros2 node info /my_node                 # node info
ros2doctor                              # diagnose
ros2 daemon stop                        # stop daemon
ros2 daemon start                       # start daemon


ros2 run rqt_top rqt_top               # CPU monitoring
ros2 run rqt_console rqt_console       # view logs
ros2 param get /my_node --format 3     # parameter details
```
---
# # Interface (msg/srv/action)

```bash
ros2 interface list                      # list all interfaces
ros2 interface package std_msgs          # package interface list
ros2 interface show std_msgs/msg/String  # view interface definition
ros2 interface pkg roscpp                # all interfaces in package


ros2 pkg create --pkg-name my_interface --destination-directory src

```
---
# # TF2

```bash
ros2 run tf2_ros static_transform_publisher x y z qx qy qz qw parent child
ros2 run rqt_tf_tree rqt_tf_tree        # TF tree visualization
ros2 run tf2_tools view_frames          # generate PDF computation graph
```
---
QoS

```bash

QoS(10).reliable()                  # control commands
QoS(10).best_effort()               # sensor data
QoS(10).transient_local()           # lifecycle state


ros2 run rqt_qos_player rqt_qos_player
ros2 topic info /my_topic -v        # view topic QoS
```
---
Debug error

```bash

colcon build --packages-select MY_PKG --cmake-args -DCMAKE_VERBOSE_MAKEFILE=ON 2>&1 | grep error


gdb -ex run --args /opt/ros/humble/lib/pkg/my_node

ros2 run MY_PKG my_node -- Department's--start-section-editing-args "debug"


valgrind --leak-check=full ros2 run MY_PKG my_node


ros2 doctor | grep -i error
```
---
# # Docker/Cross-platform

```bash

docker run --rm -v $(pwd):/ws ros:humble ./build.sh


export ROS2_INSTALLATION_TYPES=onnx
ament_tools/scripts/ament_tools/build.py --arch arm64


export CROSS_COMPILE=aarch64-linux-gnu-
colcon build --cmake-args -DCMAKE_TOOLCHAIN_FILE=aarch64.toolchain.cmake
```
---
# # Toolchain scripts

```bash

bash scripts/generators/ros2-package-generator.sh PKG cpp rclcpp,std_msgs
bash scripts/ros2-build-verify-loop.sh PKG          # Build loop verification
bash scripts/ros2-cpp-node.sh lifecycle PKG rclcpp
bash scripts/ros2-debug.sh                          # 8-class error diagnosis
bash scripts/ros2-format.sh                          # code formatting
bash scripts/ros2-orchestrate.sh                    # unified orchestration


bash scripts/generators/ros2-package-generator.sh --help
```
