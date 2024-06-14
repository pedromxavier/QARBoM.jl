mutable struct BernoulliRBM <: AbstractRBM
    W::Matrix{Float64} # weight matrix
    a::Vector{Float64} # visible bias
    b::Vector{Float64} # hidden bias
    n_visible::Int # number of visible units
    n_hidden::Int # number of hidden units
end

function BernoulliRBM(n_visible::Int, n_hidden::Int)
    W = randn(n_visible, n_hidden)
    a = zeros(n_visible)
    b = zeros(n_hidden)
    return BernoulliRBM(W, a, b, n_visible, n_hidden)
end

# Energy function: -aᵀv - bᵀh - vᵀWh
function energy(rbm::BernoulliRBM, v::Vector{Int}, h::Vector{Int})
    return -rbm.a' * v - rbm.b' * h - v' * rbm.W * h
end

# P(vᵢ = 1 | h) = sigmoid(aᵢ + Σⱼ Wᵢⱼ hⱼ)
function _prob_v_given_h(
    rbm::BernoulliRBM,
    v_i::Int,
    h::Vector{T},
) where {T<:Union{Int,Float64}}
    return _sigmoid(rbm.a[v_i] + rbm.W[v_i, :]' * h)
end

function _prob_v_given_h(
    rbm::BernoulliRBM,
    W_fast::Matrix{Float64},
    a_fast::Vector{Float64},
    v_i::Int,
    h::Vector{T},
) where {T<:Union{Int,Float64}}
    return _sigmoid((rbm.a[v_i] + a_fast[v_i] )+ (rbm.W[v_i, :] + W_fast[v_i, :])' * h)
end

# P(hⱼ = 1 | v) = sigmoid(bⱼ + Σᵢ Wᵢⱼ vᵢ)
function _prob_h_given_v(
    rbm::BernoulliRBM,
    h_i::Int,
    v::Vector{T},
) where {T<:Union{Int,Float64}}
    return _sigmoid(rbm.b[h_i] + rbm.W[:, h_i]' * v)
end

function _prob_h_given_v(
    rbm::BernoulliRBM,
    W_fast::Matrix{Float64},
    b_fast::Vector{Float64},
    h_i::Int,
    v::Vector{T},
) where {T<:Union{Int,Float64}}
    return _sigmoid((rbm.b[h_i] + b_fast[h_i]) + (rbm.W[:, h_i] + W_fast[:, h_i])' * v)
end

# Gibbs sampling
gibbs_sample_hidden(rbm::BernoulliRBM, v::Vector{T}) where {T<:Union{Int,Float64}} =
    [rand() < _prob_h_given_v(rbm, h_i, v) ? 1 : 0 for h_i = 1:num_hidden_nodes(rbm)]
gibbs_sample_hidden(rbm::BernoulliRBM, v::Vector{T}, W_fast::Matrix{Float64}, b_fast::Vector{Float64}) where {T<:Union{Int,Float64}} =
    [rand() < _prob_h_given_v(rbm, W_fast, b_fast, h_i, v) ? 1 : 0 for h_i = 1:num_hidden_nodes(rbm)]
gibbs_sample_visible(rbm::BernoulliRBM, h::Vector{T}) where {T<:Union{Int,Float64}} =
    [rand() < _prob_v_given_h(rbm, v_i, h) ? 1 : 0 for v_i = 1:num_visible_nodes(rbm)]
gibbs_sample_visible(rbm::BernoulliRBM, h::Vector{T}, W_fast::Matrix{Float64}, a_fast::Vector{Float64}) where {T<:Union{Int,Float64}} =
    [rand() < _prob_v_given_h(rbm, W_fast, a_fast, v_i, h) ? 1 : 0 for v_i = 1:num_visible_nodes(rbm)]


conditional_prob_h(rbm::BernoulliRBM, v::Vector{T}) where {T<:Union{Int,Float64}} =
    [_prob_h_given_v(rbm, h_i, v) for h_i = 1:num_hidden_nodes(rbm)]
conditional_prob_v(rbm::BernoulliRBM, h::Vector{T}) where {T<:Union{Int,Float64}} =
    [_prob_v_given_h(rbm, v_i, h) for v_i = 1:num_visible_nodes(rbm)]

function reconstruct(rbm::BernoulliRBM, v::Vector{Int})
    h = conditional_prob_h(rbm, v)
    v_reconstructed = conditional_prob_v(rbm, h)
    return v_reconstructed
end
