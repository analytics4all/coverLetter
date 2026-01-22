# Stage 1: Builder - install dependencies using uv
# Use a Python slim image for a good base
FROM python:3.12-slim AS build

# Set environment variables to optimize uv for Docker (e.g., compile bytecode)
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Copy the uv binary from the official uv image for efficient installation
COPY --from=docker.io/astral/uv:latest /uv /usr/local/bin/uv

# Set the working directory
WORKDIR /app

# Create a virtual environment where packages will be installed
RUN uv venv /app/.venv

# Add the virtual environment to the PATH so commands like 'python' use it
ENV PATH="/app/.venv/bin:$PATH"

# Copy dependency files (pyproject.toml and uv.lock) first to leverage Docker layer caching
COPY pyproject.toml uv.lock ./

# Install dependencies using uv sync in locked mode
# Use a cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked --no-install-project

# Copy the rest of the application code
COPY . .

# Re-run uv sync to install the project itself in non-editable mode
# This is intended for deployment use-cases
RUN uv sync --no-editable

# Stage 2: Runtime - a minimal image for running the application
# Use a minimal base image, potentially even distroless for security and size
FROM python:3.12-slim

# Set the working directory
WORKDIR /app

# Copy the built virtual environment and application from the builder stage
COPY --from=build /app /app

# Set the PATH again in the runtime image
ENV PATH="/app/.venv/bin:$PATH"

# Expose the port Gradio uses
EXPOSE 7860


# Command to run your application using the environment's python interpreter
# Replace 'your_app_module:app' with your actual application entry point
CMD ["python", "app3.py"]