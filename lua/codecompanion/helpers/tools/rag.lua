local xml2lua = require("codecompanion.utils.xml.xml2lua")

---@class CodeCompanion.Tool
return {
  name = "rag",
  env = function(tool)
    local url
    local key
    local value

    local action = tool.action._attr.type
    if action == "search" then
      url = "https://s.jina.ai"
      key = "q"
      value = tool.action.query
    elseif action == "navigate" then
      url = "https://r.jina.ai"
      key = "url"
      value = tool.action.url
    end

    return {
      url = url,
      key = key,
      value = value,
    }
  end,
  cmds = {
    {
      "curl",
      "-X",
      "POST",
      "${url}/",
      "-H",
      "Content-Type: application/json",
      "-H",
      "X-Return-Format: text",
      "-d",
      '{"${key}": "${value}"}',
    },
  },
  schema = {
    {
      tool = {
        _attr = { name = "rag" },
        action = {
          _attr = { type = "search" },
          query = "<![CDATA[What's the newest version of Neovim?]]>",
        },
      },
    },
    {
      tool = {
        _attr = { name = "rag" },
        action = {
          _attr = { type = "navigate" },
          url = "<![CDATA[https://github.com/neovim/neovim/releases]]>",
        },
      },
    },
  },
  system_prompt = function(schema)
    return string.format(
      [[### Retrieval Augmented Generated (RAG) Tool

1. **Purpose**: This gives you the ability to access the internet to find information that you may not know.

2. **Usage**: Return an XML markdown code block for to search the internet or navigate to a specific URL.

3. **Key Points**:
  - **Use at your discretion** when you feel you don't have access to the latest information
  - This tool is expensive so you may wish to ask the user before using it
  - Ensure XML is **valid and follows the schema**
  - **Don't escape** special characters
  - **Wrap query's and URLs in a CDATA block**, the text could contain characters reserved by XML

4. **Actions**:

a) **Search the internet**:

```xml
%s
```

b) **Navigate to a URL**:

```xml
%s
```

Remember:
- Minimize explanations unless prompted. Focus on generating correct XML.]],
      xml2lua.toXml({ tools = { schema[1] } }),
      xml2lua.toXml({ tools = { schema[2] } })
    )
  end,
  output_error_prompt = function(error)
    if type(error) == "table" then
      error = table.concat(error, "\n")
    end
    return string.format(
      [[After the RAG tool completed, there was an error:

<error>
%s
</error>
]],
      error
    )
  end,
  output_prompt = function(output)
    if type(output) == "table" then
      output = table.concat(output, "\n")
    end

    return string.format(
      [[Here is the content that the RAG tool found:

<content>
%s
</content>]],
      output
    )
  end,
}
