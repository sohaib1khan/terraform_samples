#!/bin/bash

while getopts "y" opt; do
  case ${opt} in
    y )
      confirm="y"
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [[ "$confirm" != "y" ]]; then
  echo "This script will delete unused Docker resources, including images, containers, networks, and volumes."
  read -p "Do you want to continue? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    read -p "Do you want to delete all unused containers? (y/n) " container_choice
    if [[ "$container_choice" =~ ^[Yy]$ || "$confirm" == "y" ]]; then
      docker container prune -f
    fi

    read -p "Do you want to delete all dangling images? (y/n) " image_choice
    if [[ "$image_choice" =~ ^[Yy]$ || "$confirm" == "y" ]]; then
      docker image prune -f
    fi

    read -p "Do you want to delete all unused volumes? (y/n) " volume_choice
    if [[ "$volume_choice" =~ ^[Yy]$ || "$confirm" == "y" ]]; then
      docker volume prune -f
    fi

    read -p "Do you want to delete all unused networks? (y/n) " network_choice
    if [[ "$network_choice" =~ ^[Yy]$ || "$confirm" == "y" ]]; then
      docker network prune -f
    fi

    docker system df
  else
    echo "Operation canceled by user."
  fi
else
  docker container prune -f
  docker image prune -f
  docker volume prune -f
  docker network prune -f
  docker system df
fi
