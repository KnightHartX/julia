__precompile__()

module SHA
using Compat

# Export convenience functions, context types, update!() and digest!() functions
export sha1, SHA1_CTX, update!, digest!
export sha224, sha256, sha384, sha512
export sha2_224, sha2_256, sha2_384, sha2_512
export sha3_224, sha3_256, sha3_384, sha3_512
export SHA224_CTX, SHA256_CTX, SHA384_CTX, SHA512_CTX
export SHA2_224_CTX, SHA2_256_CTX, SHA2_384_CTX, SHA2_512_CTX
export SHA3_224_CTX, SHA3_256_CTX, SHA3_384_CTX, SHA3_512_CTX
export HMAC_CTX, hmac_sha1
export hmac_sha224, hmac_sha256, hmac_sha384, hmac_sha512
export hmac_sha2_224, hmac_sha2_256, hmac_sha2_384, hmac_sha2_512
export hmac_sha3_224, hmac_sha3_256, hmac_sha3_384, hmac_sha3_512


include("constants.jl")
include("types.jl")
include("base_functions.jl")
include("sha1.jl")
include("sha2.jl")
include("sha3.jl")
include("common.jl")
include("hmac.jl")

# Compat.jl-like shim for codeunits() on Julia <= 0.6:
if VERSION < v"0.7.0-DEV.3213"
    codeunits(x) = x
end

# Create data types and convenience functions for each hash implemented
for (f, ctx) in [(:sha1, :SHA1_CTX),
                 (:sha224, :SHA224_CTX),
                 (:sha256, :SHA256_CTX),
                 (:sha384, :SHA384_CTX),
                 (:sha512, :SHA512_CTX),
                 (:sha2_224, :SHA2_224_CTX),
                 (:sha2_256, :SHA2_256_CTX),
                 (:sha2_384, :SHA2_384_CTX),
                 (:sha2_512, :SHA2_512_CTX),
                 (:sha3_224, :SHA3_224_CTX),
                 (:sha3_256, :SHA3_256_CTX),
                 (:sha3_384, :SHA3_384_CTX),
                 (:sha3_512, :SHA3_512_CTX),]
    g = Symbol(:hmac_, f)

    @eval begin
        # Our basic function is to process arrays of bytes
        function $f(data::T) where T<:Union{Array{UInt8,1},NTuple{N,UInt8} where N}
            ctx = $ctx()
            update!(ctx, data)
            return digest!(ctx)
        end
        function $g(key::Vector{UInt8}, data::T) where T<:Union{Array{UInt8,1},NTuple{N,UInt8} where N}
            ctx = HMAC_CTX($ctx(), key)
            update!(ctx, data)
            return digest!(ctx)
        end

        # AbstractStrings are a pretty handy thing to be able to crunch through
        $f(str::AbstractString) = $f(Vector{UInt8}(codeunits(str)))
        $g(key::Vector{UInt8}, str::AbstractString) = $g(key, Vector{UInt8}(str))

        # Convenience function for IO devices, allows for things like:
        # open("test.txt") do f
        #     sha256(f)
        # done
        function $f(io::IO, chunk_size=4*1024)
            ctx = $ctx()
            buff = Vector{UInt8}(uninitialized, chunk_size)
            while !eof(io)
                num_read = readbytes!(io, buff)
                update!(ctx, buff[1:num_read])
            end
            return digest!(ctx)
        end
        function $g(key::Vector{UInt8}, io::IO, chunk_size=4*1024)
            ctx = HMAC_CTX($ctx(), key)
            buff = Vector{UInt8}(chunk_size)
            while !eof(io)
                num_read = readbytes!(io, buff)
                update!(ctx, buff[1:num_read])
            end
            return digest!(ctx)
        end
    end
end

end #module SHA