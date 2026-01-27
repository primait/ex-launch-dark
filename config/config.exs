import Config

# Import dev.exs if exists to perform local testing
dev_config = Path.expand("dev.exs", __DIR__)
if File.exists?(dev_config), do: import_config("dev.exs")
