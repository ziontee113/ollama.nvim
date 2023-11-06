local M = {}

local params = {
    {
        param = "mirostat",
        desc = "Enable Mirostat sampling for controlling perplexity. (default: 0, 0 = disabled, 1 = Mirostat, 2 = Mirostat 2.0)",
        default = 0,
    },
    {
        param = "mirostat_eta",
        desc = "Influences how quickly the algorithm responds to feedback from the generated text. A lower learning rate will result in slower adjustments, while a higher learning rate will make the algorithm more responsive.",
        default = 0.1,
    },
    {
        param = "mirostat_tau",
        desc = "Controls the balance between coherence and diversity of the output. A lower value will result in more focused and coherent text.",
        default = 5.0,
    },
    {
        param = "num_ctx",
        desc = "Sets the size of the context window used to generate the next token.",
        default = 2048,
    },
    {
        param = "num_gqa",
        desc = "The number of GQA groups in the transformer layer. Required for some models, for example it is 8 for llama2:70b.",
        default = 1,
    },
    {
        param = "num_gpu",
        desc = "The number of layers to send to the GPU(s). On macOS it defaults to 1 to enable metal support, 0 to disable.",
        default = 50,
    },
    {
        param = "num_thread",
        desc = "Sets the number of threads to use during computation. By default, Ollama will detect this for optimal performance. It is recommended to set this value to the number of physical CPU cores your system has (as opposed to the logical number of cores).",
        default = 8,
    },
    {
        param = "repeat_last_n",
        desc = "Sets how far back for the model to look back to prevent repetition. (Default: 64, 0 = disabled, -1 = num_ctx)",
        default = 64,
    },
    {
        param = "repeat_penalty",
        desc = "Sets how strongly to penalize repetitions. A higher value (e.g., 1.5) will penalize repetitions more strongly, while a lower value (e.g., 0.9) will be more lenient.",
        default = 1.1,
    },
    {
        param = "temperature",
        desc = "The temperature of the model. Increasing the temperature will make the model answer more creatively.",
        default = 0.8,
    },
    {
        param = "seed",
        desc = "Sets the random number seed to use for generation. Setting this to a specific number will make the model generate the same text for the same prompt.",
        default = 0,
    },
    {
        param = "stop",
        desc = "Sets the stop sequences to use.",
        default = "AI assistant:",
    },
    {
        param = "tfs_z",
        desc = "Tail free sampling is used to reduce the impact of less probable tokens from the output. A higher value (e.g., 2.0) will reduce the impact more, while a value of 1.0 disables this setting.",
        default = 1,
    },
    {
        param = "num_predict",
        desc = "Maximum number of tokens to predict when generating text. (Default: 128, -1 = infinite generation, -2 = fill context)",
        default = 42,
    },
    {
        param = "top_k",
        desc = "Reduces the number of possible answers before ranking them by probability. A higher value (e.g., 0.95) will give more diverse answers, while a lower value (e.g., 0.85) will be more conservative.",
        default = 40,
    },
    {
        param = "top_p",
        desc = "Works together with top-k. A higher value (e.g., 0.95) will give more diverse answers, while a lower value (e.g., 0.85) will be more conservative.",
        default = 0.85,
    },
}

return M
