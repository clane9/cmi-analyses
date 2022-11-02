#!/bin/bash

PORT=8093
NODE=r004
# ssh -L ${PORT}:localhost:${PORT} bridges2 ssh -L ${PORT}:localhost:${PORT} -N ${NODE}
ssh -L ${PORT}:localhost:${PORT} -N ${NODE}
