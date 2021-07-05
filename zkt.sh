#!/bin/bash

install_docker(){
        docker_check=`docker version | grep Engine | wc -l`
        if [ ${docker_check} = "0" ]; then
            echo "-----------------------------------------------------"
            echo "开始使用Docker官方脚本部署Docker!"
            read -p "当前版本是否为CentOS8版本(输入Y或N): " if_CentOS8
                if [ ${if_CentOS8} = "Y" -o ${if_CentOS8} = "y" ]; then
                        echo T | sudo yum remove containerd.io
                        sudo yum install -y yum-utils
                        sudo yum install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
                        echo Y | sudo yum install docker-ce docker-ce-cli -y --nobest
                        sudo systemctl start docker
                        sudo systemctl enable docker
                        sudo docker version
                else
                    curl -fsSL https://get.docker.com -o get-docker.sh
                    sh get-docker.sh
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    sudo docker version
            fi
        else
            echo "-----------------------------------------------------"
            echo "Docker已安装，无需操作!"
        fi
}

downloadd_tpm_image() {
        image_count=`docker image ls | topmininglabs/zktube-image | wc -l`
        if [ ${image_count} != "0" ]; then
                echo "-----------------------------------------------------"
            echo "已下载专供镜像，无需操作!"
            
        else
            echo "-----------------------------------------------------"
            echo "开始下载/更新专供zkTube最新镜像: "
            docker pull topmininglabs/zktube-image:latest
            echo "-----------------------------------------------------"
            docker image ls
            image_count=`docker image ls | grep topmininglabs/zktube-image | wc -l`
            if [ ${image_count} != "0" ]; then
                echo "-----------------------------------------------------"
                echo "专供zkTube最新镜像已下载/更新完成!"
            else
                echo "-----------------------------------------------------"
                echo "镜像下载失败，请确认网络连接正常且正确安装Docker后再重试！"
                all
            fi
        fi
}

create_revenue_address() {
        echo "-----------------------------------------------------"
        mkdir ${HOME}/zktube && touch ${HOME}/zktube/.revenue_address
        read -p "请输入ETH收益地址: " ETH_address
        echo $ETH_address > ${HOME}/zktube/.revenue_address
        echo "-----------------------------------------------------"
        echo "已设置ETH收益地址为: "
        cat ${HOME}/zktube/.revenue_address
}

modify_revenue_address() {
        echo "-----------------------------------------------------"
        echo "当前设置的ETH收益地址为: "
        cat ${HOME}/zktube/.revenue_address
        read -p "是否确认修改该ETH收益地址(输入Y开始修改，输入N取消修改): " modify_file
                if [ ${modify_file} = "Y" -o ${modify_file} = "y" ]; then
                        rm ${HOME}/zktube/.revenue_address && touch ${HOME}/zktube/.revenue_address
                        read -p "请输入新的ETH收益地址: " ETH_address
                                echo $ETH_address > ${HOME}/zktube/.revenue_address
                                echo "-----------------------------------------------------"
                                echo "已设置新的ETH收益地址为: "
                                cat ${HOME}/zktube/.revenue_address
                else all
                fi
}

deploy_zktnode() {
        image_count=`docker image ls | grep topmininglabs/zktube-prover | wc -l`
        if [ ${image_count} = "0" ]; then
                echo "-----------------------------------------------------"
            echo "尚未下载专供镜像，请先下载后再执行次操作!"
            exit 1
        else
                echo "-----------------------------------------------------"
                echo "请确保已正确设置ETH收益地址！"
                echo "当前设置的ETH收益地址为: "
                cat ${HOME}/zktube/.revenue_address
                read -p "是否确认以该ETH收益地址部署节点(输入Y开始部署，输入N取消部署): " decide
                if [ ${decide} = "Y" -o ${decide} = "y" ]; then
                        read -p "请输入要部署的zkTube节点数量: " node_count
                        for ((i=1; i<=node_count; i ++))
                        do
                                echo "-----------------------------------------------------"
                                echo "开始部署专供zkTube新节点: "
                                docker run -d -v ~/zktube/.revenue_address:/revenue_address --restart always --name zktube_${i} topmininglabs/zktube-prover:latest
                                echo "-----------------------------------------------------"
                                str1="zkTube节点zktube_"
                                str2=${i}
                                str3="已部署完成!"
                                echo ${str1}${str2}${str3}
                                echo "-----------------------------------------------------"
                                sleep 1
                        done
                else all
                fi
        fi
}

check_revenue_address() {
        echo "-----------------------------------------------------"
        echo "ETH收益地址为: "
        cat ${HOME}/zktube/.revenue_address
}

check_zktnode_status() {
        node_count=`docker ps --filter="name=zktube_" | wc -l`
        if [ ${node_count} = "0" ]; then
                echo "-----------------------------------------------------"
            echo "尚未部署专供zkTube节点,请部署后再执行此操作!"
            all
        else
                echo "-----------------------------------------------------"
                echo "当前专供zkTube节点运行状态如下: "
                docker ps --filter="name=zktube_"
        fi
}

check_logs_single() {
        node_count=`docker ps --filter="name=zktube_" | wc -l`
        if [ ${node_count} = "0" ]; then
                echo "-----------------------------------------------------"
            echo "尚未部署专供zkTube节点,请部署后再执行此操作!"
            all
        else
                echo "-----------------------------------------------------"
                read -p "请输入要查看的zkTube节点序号: " node_number
                read -p "请输入要查看的日志行数: " col_number
                str1="开始查询节点zktube_"
                str2=${node_number}
                str3="日志: "
                echo $str1${str2}$str3
                docker logs --tail ${col_number} zktube_${node_number} 
        fi
}

check_logs_all() {
        node_count=`docker ps --filter="name=zktube_" | wc -l`
        if [ ${node_count} = "0" ]; then
                echo "-----------------------------------------------------"
            echo "尚未部署专供zkTube节点,请部署后再执行此操作!"
            all
        else
                read -p "请输入要查看的日志行数: " col_number
                for ((i=1; i<=node_count - 1; i ++))
                do
                echo "-----------------------------------------------------"
                        str1="开始查询节点zktube_"
                        str2=${i}
                        str3="日志: "
                        echo ${str1}${str2}${str3}
                docker logs --tail ${col_number} zktube_${i} 
                sleep 2
                done
        fi
}

delete_revenue_address() {
        echo "-----------------------------------------------------"
        echo "当前设置的ETH收益地址为: "
        cat ${HOME}/zktube/.revenue_address
        read -p "是否确认彻底删除该地址文件(输入Y开始删除，输入N取消删除): " delete_file
                if [ ${delete_file} = "Y" -o ${delete_file} = "y" ]; then
                        rm -R ${HOME}/zktube
                        echo "已彻底删除通过此脚本创建的revenue_address文件!"
                else all
                fi
}
delete_zktnode_all() {
        node_count1=`docker ps -a --filter="name=zktube_" | wc -l`
        if [ ${node_count1} = "0" ]; then
                echo "-----------------------------------------------------"
            echo "未部署专供zkTube节点,无需删除!"
            all
        else
                echo "-----------------------------------------------------"
                echo "当前运行中的专供zkTube节点为: "
                docker ps --filter="name=zktube_"
                node_count2=`docker ps --filter="name=zktube_" | wc -l`
                read -p "是否确认彻底删除全部zkTube节点(输入Y开始删除，输入N取消删除): " delete_node
                if [ ${delete_node} = "Y" -o ${delete_node} = "y" ]; then
                        for ((i=1; i<=node_count2 - 1; i ++))
                        do
                                echo "-----------------------------------------------------"
                    str1="开始删除zkTube节点zktube_"
                    str2=${i}
                    str3="： "
                    echo ${str1}${str2}${str3}
                    docker stop zktube_${i}
                    docker rm zktube_${i}
                    str4="zkTube节点zktube_"
                    str5=${i}
                    str6="已成功删除!"
                    echo ${str4}${str5}${str6}
                    sleep 2
                done 
                echo "已彻底删除通过此脚本部署的全部zkTube节点!"
                docker ps
            else all
            fi
        fi
}

delete_tpm_image() {
        node_count1=`docker ps -a --filter="name=zktube_" | wc -l`
        if [ ${node_count1} != "0" ]; then
                echo "-----------------------------------------------------"
            echo "以下专供zkTube节点尚未删除，请先删除节点后再执行镜像删除操作!"
            docker ps -a --filter="name=zktube_"
            all
        else
                echo "-----------------------------------------------------"
                echo "当前运行中的Docker镜像文件为: "
                docker image ls
                image_count=`docker image ls | grep topmininglabs/zktube-prover | wc -l`
                if [ ${image_count} = "0" ]; then
                        echo "-----------------------------------------------------"
                echo "尚未下载专供镜像，无需执行次操作!"
                exit 1
            else
                read -p "是否确认彻底删除通过此脚本下载的专供zkTube镜像(输入Y开始删除，输入N取消删除): " delete_image
                if [ ${delete_image} = "Y" -o ${delete_image} = "y" ]; then
                                echo "-----------------------------------------------------"
                        echo "开始删除专供zkTube镜像: "
                        docker rmi topmininglabs/zktube-prover:latest
                        echo "已彻底删除专供zkTube镜像!"
                        docker image ls
                else
                        exit 1
                fi
            fi
        fi
}

all(){
while true 
        do
cat << EOF

===本脚本的命令仅支持用专供zkTube镜像部署的节点===
==专供zkTube镜像为官方镜像的纯净打包版无任何修改可放心使用==
(1) 安装Docker
(2) 下载/更新专供zkTube最新镜像
(3) 创建revenue_address文件并设置收益地址
(4) 修改ETH收益地址
(5) 部署zkTube节点
(6) 查看收益地址
(7) 检查通过此脚本创建的zkTube节点运行状态
(8) 查看通过此脚本创建的单个zkTube节点运行日志
(9) 查看通过此脚本创建的所有zkTube节点运行日志
(10) 删除通过此脚本创建的revenue_address文件
(11) 删除通过此脚本部署的全部zkTube节点
(12) 删除通过此脚本下载的专供zkTube镜像
(0) Exit
-----------------------------------------------------
EOF
                read -p "请输入要执行的选项: " input
                case $input in
                        1)
                                echo "安装Docker"
                                install_docker
                                ;;
                        2)
                                echo "下载/更新专供zkTube最新镜像"
                                downloadd_tpm_image
                                ;;
                        3)
                                echo "创建revenue_address文件并配置收益地址"
                                create_revenue_address
                                ;;
                        4)
                                echo "修改ETH收益地址"
                                modify_revenue_address
                                ;;
                        5)
                                echo "部署zkTube节点"
                                deploy_zktnode
                                ;;
                        6)
                                echo "查看收益地址"
                                check_revenue_address
                                ;;
                        7)
                                echo "检查通过此脚本创建的zkTube节点运行状态"
                                check_zktnode_status
                                ;;
                        8)
                                echo "查看通过此脚本创建的单个zkTube节点运行日志"
                                check_logs_single
                                ;;
                        9)
                                echo "查看通过此脚本创建的所有zkTube节点运行日志"
                                check_logs_all
                                ;;
                        10)
                                echo "删除通过此脚本创建的revenue_address文件"
                                delete_revenue_address
                                ;;
                        11)
                                echo "删除通过此脚本部署的全部zkTube节点"
                                delete_zktnode_all
                                ;;
                        12)
                                echo "删除通过此脚本下载的专供zkTube镜像"
                                delete_tpm_image
                                ;;
                        *)
                                exit 1
                                ;;
                esac

done
}

while true 
        do
cat << EOF

===本脚本的命令仅支持用专供zkTube镜像部署的节点===
==专供zkTube镜像为官方镜像的纯净打包版无任何修改可放心使用==
(1) 安装Docker
(2) 下载/更新专供zkTube最新镜像
(3) 创建revenue_address文件并设置收益地址
(4) 修改ETH收益地址
(5) 部署zkTube节点
(6) 查看收益地址
(7) 检查通过此脚本创建的zkTube节点运行状态
(8) 查看通过此脚本创建的单个zkTube节点运行日志
(9) 查看通过此脚本创建的所有zkTube节点运行日志
(10) 删除通过此脚本创建的revenue_address文件
(11) 删除通过此脚本部署的全部zkTube节点
(12) 删除通过此脚本下载的专供zkTube镜像
(0) Exit
-----------------------------------------------------
EOF
                read -p "请输入要执行的选项: " input
                case $input in
                        1)
                                echo "安装Docker"
                                install_docker
                                ;;
                        2)
                                echo "下载/更新专供zkTube最新镜像"
                                downloadd_tpm_image
                                ;;
                        3)
                                echo "创建revenue_address文件并配置收益地址"
                                create_revenue_address
                                ;;
                        4)
                                echo "修改ETH收益地址"
                                modify_revenue_address
                                ;;
                        5)
                                echo "部署zkTube节点"
                                deploy_zktnode
                                ;;
                        6)
                                echo "查看收益地址"
                                check_revenue_address
                                ;;
                        7)
                                echo "检查通过此脚本创建的zkTube节点运行状态"
                                check_zktnode_status
                                ;;
                        8)
                                echo "查看通过此脚本创建的单个zkTube节点运行日志"
                                check_logs_single
                                ;;
                        9)
                                echo "查看通过此脚本创建的所有zkTube节点运行日志"
                                check_logs_all
                                ;;
                        10)
                                echo "删除通过此脚本创建的revenue_address文件"
                                delete_revenue_address
                                ;;
                        11)
                                echo "删除通过此脚本部署的全部zkTube节点"
                                delete_zktnode_all
                                ;;
                        12)
                                echo "删除通过此脚本下载的专供zkTube镜像"
                                delete_tpm_image
                                ;;
                        *)
                                exit 1
                                ;;
                esac

done
