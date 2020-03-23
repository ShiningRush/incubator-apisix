--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local core        = require("apisix.core")
local ngx         = ngx
local plugin_name = "cors"
local str_find    = string.find
local str_gmatch  = string.gmatch

local schema = {
    type = "object",
    properties = {
        allow_origins = {
            description = "you can use '*' to allow all origins when no credentials and '**', "..
                        "to allow forcefully(it will bring some security risks, be carefully), "..
                        "multiple origin use ',' to split. default: *.",
            type = "string"
        },
        allow_methods = {
            description = "you can use '*' to allow all methods when no credentials and '**', "..
            "to allow forcefully(it will bring some security risks, be carefully), "..
            "multiple method use ',' to split. default: *.",
            type = "string"
        },
        allow_headers = {
            description = "you can use '*' to allow all header when no credentials, "..
                        "multiple header use ',' to split. default: *.",
            type = "string"
        },
        expose_headers = {
            description = "you can use '*' to expose all header when no credentials, "..
                        "multiple header use ',' to split. default: *.",
            type = "string"
        },
        max_age = {
            description = "maximum number of seconds the results can be cached."..
                        "-1 mean no cached,the max value is depend on browser,"..
                        "more detail plz check MDN. default: 5.",
            type = "integer"
        },
        allow_credential = {
            type = "boolean"
        },
    }
}

local _M = {
    version = 0.1,
    priority = 4000,
    type = 'auth',
    name = plugin_name,
    schema = schema,
}

function _M.check_schema(conf)
    local ok, err = core.schema.check(schema, conf)
    if not ok then
        return false, err
    end

    if not conf.allow_origins then
        conf.allow_origins = "*"
    end

    if not conf.allow_methods then
        conf.allow_methods = "*"
    end

    if not conf.allow_headers then
        conf.allow_headers = "*"
    end

    if not conf.expose_headers then
        conf.expose_headers = "*"
    end

    if not conf.max_age then
        conf.max_age = 5
    end

    if not conf.allow_credential then
        conf.allow_credential = false
    end

    return true
end

function _M.header_filter(conf, ctx)
    if conf.allow_origins == "**" then
        conf.allow_origins = ngx.var.http_origin or '*'
    end
    if str_find(conf.allow_origins, ",") then
        local finded = false
        for origin in str_gmatch(conf.allow_origins, "([^,]+)") do
            if origin == ngx.var.http_origin then
                conf.allow_origins = origin
                finded = true
                break
            end
        end
        if not finded then
            return
        end
    end

    if conf.allow_methods == "**" then
        conf.allow_methods = "GET,POST,PUT,DELETE,PATCH,HEAD,OPTIONS,CONNECT,TRACE"
    end

    ngx.header["Access-Control-Allow-Origin"] = conf.allow_origins
    ngx.header["Access-Control-Allow-Methods"] = conf.allow_methods
    ngx.header["Access-Control-Allow-Headers"] = conf.allow_headers
    ngx.header["Access-Control-Expose-Headers"] = conf.expose_headers
    ngx.header["Access-Control-Max-Age"] = conf.max_age
    if conf.allow_credential then
        ngx.header["Access-Control-Allow-Credentials"] = true
    end

    if ctx.var.request_method == "OPTIONS" then
        return 200
    end
end

return _M
