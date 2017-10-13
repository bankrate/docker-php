#!/bin/bash

if [ -f /app/composer.json ]; then
  composer install
fi
