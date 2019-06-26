import operator

import numpy as np
cimport numpy as np

from randomgen.common cimport *
from randomgen.distributions cimport bitgen_t
from randomgen.entropy import random_entropy

__all__ = ['DSFMT']

DEF DSFMT_MEXP = 19937
DEF DSFMT_N = 191  # ((DSFMT_MEXP - 128) / 104 + 1)
DEF DSFMT_N_PLUS_1 = 192  # DSFMT_N + 1
DEF DSFMT_N64 = DSFMT_N * 2

cdef extern from "src/dsfmt/dSFMT.h":

    union W128_T:
        uint64_t u[2]
        uint32_t u32[4]
        double d[2]

    ctypedef W128_T w128_t

    struct DSFMT_T:
        w128_t status[DSFMT_N_PLUS_1]
        int idx

    ctypedef DSFMT_T dsfmt_t

    struct s_dsfmt_state:
        dsfmt_t *state
        int has_uint32
        uint32_t uinteger

        double *buffered_uniforms
        int buffer_loc

    ctypedef s_dsfmt_state dsfmt_state

    double dsfmt_next_double(dsfmt_state *state)  nogil
    uint64_t dsfmt_next64(dsfmt_state *state)  nogil
    uint32_t dsfmt_next32(dsfmt_state *state)  nogil
    uint64_t dsfmt_next_raw(dsfmt_state *state)  nogil

    void dsfmt_init_gen_rand(dsfmt_t *dsfmt, uint32_t seed)
    void dsfmt_init_by_array(dsfmt_t *dsfmt, uint32_t init_key[], int key_length)
    void dsfmt_jump(dsfmt_state *state)
    void dsfmt_jump_n(dsfmt_state *state, int count)

cdef uint64_t dsfmt_uint64(void* st) nogil:
    return dsfmt_next64(<dsfmt_state *>st)

cdef uint32_t dsfmt_uint32(void *st) nogil:
    return dsfmt_next32(<dsfmt_state *> st)

cdef double dsfmt_double(void* st) nogil:
    return dsfmt_next_double(<dsfmt_state *>st)

cdef uint64_t dsfmt_raw(void *st) nogil:
    return dsfmt_next_raw(<dsfmt_state *>st)

cdef class DSFMT(BitGenerator):
    u"""
    DSFMT(seed=None)

    Container for the SIMD-based Mersenne Twister pseudo RNG.

    Parameters
    ----------
    seed : {None, int, array_like}, optional
        Random seed used to initialize the pseudo-random number generator.  Can
        be any integer between 0 and 2**32 - 1 inclusive, an array (or other
        sequence) of unsigned 32-bit integers, or ``None`` (the default).  If
        `seed` is ``None``, then 764 32-bit unsigned integers are read from
        ``/dev/urandom`` (or the Windows analog) if available. If unavailable,
        a hash of the time and process ID is used.

    Attributes
    ----------
    lock: threading.Lock
        Lock instance that is shared so that the same bit git generator can
        be used in multiple Generators without corrupting the state. Code that
        generates values from a bit generator should hold the bit generator's
        lock.

    Notes
    -----
    ``DSFMT`` provides a capsule containing function pointers that produce
    doubles, and unsigned 32 and 64- bit integers [1]_ . These are not
    directly consumable in Python and must be consumed by a ``Generator``
    or similar object that supports low-level access.

    The Python stdlib module "random" also contains a Mersenne Twister
    pseudo-random number generator.

    **State and Seeding**

    The ``DSFMT`` state vector consists of a 384 element array of 64-bit
    unsigned integers plus a single integer value between 0 and 382
    indicating the current position within the main array. The implementation
    used here augments this with a 382 element array of doubles which are used
    to efficiently access the random numbers produced by the dSFMT generator.

    ``DSFMT`` is seeded using either a single 32-bit unsigned integer or a
    vector of 32-bit unsigned integers. In either case, the input seed is used
    as an input (or inputs) for a hashing function, and the output of the
    hashing function is used as the initial state. Using a single 32-bit value
    for the seed can only initialize a small range of the possible initial
    state values.

    **Parallel Features**

    ``DSFMT`` can be used in parallel applications by calling the method
    ``jump`` which advances the state as-if :math:`2^{128}` random numbers
    have been generated [2]_. This allows the original sequence to be split
    so that distinct segments can be used in each worker process. All
    generators should be initialized with the same seed to ensure that
    the segments come from the same sequence.

    >>> from randomgen.entropy import random_entropy
    >>> from randomgen import Generator, DSFMT
    >>> seed = random_entropy()
    >>> rs = [Generator(DSFMT(seed)) for _ in range(10)]
    # Advance each DSFMT instance by i jumps
    >>> for i in range(10):
    ...     rs[i].bit_generator.jump()

    **Compatibility Guarantee**

    ``DSFMT`` makes a guarantee that a fixed seed and will always produce
    the same random integer stream.

    References
    ----------
    .. [1] Mutsuo Saito and Makoto Matsumoto, "SIMD-oriented Fast Mersenne
           Twister: a 128-bit Pseudorandom Number Generator." Monte Carlo
           and Quasi-Monte Carlo Methods 2006, Springer, pp. 607--622, 2008.
    .. [2] Hiroshi Haramoto, Makoto Matsumoto, and Pierre L\'Ecuyer, "A Fast
           Jump Ahead Algorithm for Linear Recurrences in a Polynomial Space",
           Sequences and Their Applications - SETA, 290--298, 2008.
    """
    cdef dsfmt_state rng_state

    def __init__(self, seed=None):
        BitGenerator.__init__(self)
        self.rng_state.state = <dsfmt_t *>PyArray_malloc_aligned(sizeof(dsfmt_t))
        self.rng_state.buffered_uniforms = <double *>PyArray_calloc_aligned(DSFMT_N64, sizeof(double))
        self.rng_state.buffer_loc = DSFMT_N64
        self.seed(seed)

        self._bitgen.state = <void *>&self.rng_state
        self._bitgen.next_uint64 = &dsfmt_uint64
        self._bitgen.next_uint32 = &dsfmt_uint32
        self._bitgen.next_double = &dsfmt_double
        self._bitgen.next_raw = &dsfmt_raw

    def __dealloc__(self):
        if self.rng_state.state:
            PyArray_free_aligned(self.rng_state.state)
        if self.rng_state.buffered_uniforms:
            PyArray_free_aligned(self.rng_state.buffered_uniforms)

    cdef _reset_state_variables(self):
        self.rng_state.buffer_loc = DSFMT_N64

    def seed(self, seed=None):
        """
        seed(seed=None)

        Seed the generator.

        Parameters
        ----------
        seed : {None, int, array_like}, optional
            Random seed initializing the pseudo-random number generator.
            Can be an integer in [0, 2**32-1], array of integers in
            [0, 2**32-1] or ``None`` (the default). If `seed` is ``None``,
            then ``DSFMT`` will try to read entropy from ``/dev/urandom``
            (or the Windows analog) if available to produce a 32-bit
            seed. If unavailable, a 32-bit hash of the time and process
            ID is used.

        Raises
        ------
        ValueError
            If seed values are out of range for the PRNG.
        """
        cdef np.ndarray obj, seed_arr
        try:
            if seed is None:
                seed_arr = random_entropy(2 * DSFMT_N64, 'auto')
                dsfmt_init_by_array(self.rng_state.state,
                                    <uint32_t *>np.PyArray_DATA(seed_arr),
                                    2 * DSFMT_N64)

            else:
                if hasattr(seed, 'squeeze'):
                    seed = seed.squeeze()
                idx = operator.index(seed)
                if idx > int(2**32 - 1) or idx < 0:
                    raise ValueError("Seed must be between 0 and 2**32 - 1")
                dsfmt_init_gen_rand(self.rng_state.state, seed)
        except TypeError:
            obj = np.asarray(seed).astype(np.int64, casting='safe').ravel()
            if ((obj > int(2**32 - 1)) | (obj < 0)).any():
                raise ValueError("Seed must be between 0 and 2**32 - 1")
            seed_arr = obj.astype(np.uint32, casting='unsafe', order='C')
            dsfmt_init_by_array(self.rng_state.state,
                                <uint32_t *>np.PyArray_DATA(seed_arr),
                                <int>np.PyArray_DIM(seed_arr, 0))
        # Clear the buffer
        self._reset_state_variables()

    cdef jump_inplace(self, iter):
        """
        Jump state in-place

        Not part of public API

        Parameters
        ----------
        iter : integer, positive
            Number of times to jump the state of the rng.
        """
        if iter < 0:
            raise ValueError('iter must be positive')
        dsfmt_jump_n(&self.rng_state, iter)
        # Clear the buffer
        self._reset_state_variables()

    def jump(self, np.npy_intp iter=1):
        """
        jump(iter=1)

        Jumps the state as-if 2**128 random numbers have been generated.

        Parameters
        ----------
        iter : integer, positive
            Number of times to jump the state of the bit generator.

        Returns
        -------
        self : DSFMT
            PRNG jumped iter times
        """
        import warnings
        warnings.warn('jump (in-place) has been deprecated in favor of jumped'
                      ', which returns a new instance', DeprecationWarning)

        self.jump_inplace(iter)
        return self

    def jumped(self, np.npy_intp iter=1):
        """
        jumped(iter=1)

        Returns a new bit generator with the state jumped

        The state of the returned big generator is jumped as-if
        2**(128 * iter) random numbers have been generated.

        Parameters
        ----------
        iter : integer, positive
            Number of times to jump the state of the bit generator returned

        Returns
        -------
        bit_generator : DSFMT
            New instance of generator jumped iter times
        """
        cdef DSFMT bit_generator

        bit_generator = self.__class__()
        bit_generator.state = self.state
        bit_generator.jump_inplace(iter)

        return bit_generator

    @property
    def state(self):
        """
        Get or set the PRNG state

        Returns
        -------
        state : dict
            Dictionary containing the information required to describe the
            state of the PRNG
        """

        cdef Py_ssize_t i, j, loc = 0
        cdef uint64_t[::1] state
        cdef double[::1] buffered_uniforms

        state = np.empty(2 *DSFMT_N_PLUS_1, dtype=np.uint64)
        for i in range(DSFMT_N_PLUS_1):
            for j in range(2):
                state[loc] = self.rng_state.state.status[i].u[j]
                loc += 1
        buffered_uniforms = np.empty(DSFMT_N64, dtype=np.double)
        for i in range(DSFMT_N64):
            buffered_uniforms[i] = self.rng_state.buffered_uniforms[i]
        return {'bit_generator': self.__class__.__name__,
                'state': {'state': np.asarray(state),
                          'idx': self.rng_state.state.idx},
                'buffer_loc': self.rng_state.buffer_loc,
                'buffered_uniforms': np.asarray(buffered_uniforms)}

    @state.setter
    def state(self, value):
        cdef Py_ssize_t i, j, loc = 0
        if not isinstance(value, dict):
            raise TypeError('state must be a dict')
        bitgen = value.get('bit_generator', '')
        if bitgen != self.__class__.__name__:
            raise ValueError('state must be for a {0} '
                             'PRNG'.format(self.__class__.__name__))
        state = check_state_array(value['state']['state'], 2*DSFMT_N_PLUS_1,
                                  64, 'state')
        for i in range(DSFMT_N_PLUS_1):
            for j in range(2):
                self.rng_state.state.status[i].u[j] = state[loc]
                loc += 1
        self.rng_state.state.idx = value['state']['idx']
        buffered_uniforms = value['buffered_uniforms']
        # TODO: Check buffered_uniforms
        for i in range(DSFMT_N64):
            self.rng_state.buffered_uniforms[i] = buffered_uniforms[i]
        self.rng_state.buffer_loc = value['buffer_loc']
