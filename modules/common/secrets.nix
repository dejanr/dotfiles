{ pkgs, lib, config, ... }:

# Home related secrets that are managed by agenix

# Use this for not so secret secrets, that should be hidden from general public

{
  age.secrets.anthropic_api_key.file = ../../secrets/anthropic_api_key.age;
  age.secrets.deepseek_api_key.file = ../../secrets/deepseek_api_key.age;
  age.secrets.groq_api_key.file = ../../secrets/groq_api_key.age;
  age.secrets.gemini_api_key.file = ../../secrets/gemini_api_key.age;
}
