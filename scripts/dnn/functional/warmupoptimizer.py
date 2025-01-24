import torch


class NoamOpt:
    "Optim wrapper that implements rate."

    def __init__(
        self,
        *,
        optimizer: torch.optim.Optimizer,
        max_lr: dict,
        warmup_step: int,
        init_lr: dict = {"default": 0},
        lr_reduce_factor: dict = {"default": 0.5},
        min_lr: dict = {"default": 1e-8},
        best: int = 0,
        direction: bool = True,
        patience: int = 10,
        cooldown: int = 0,
        threshold: float = 1e-2,
        thresmode: str = "abs",
        scheduled_epoch: dict[str,list[int]]= {"default": [20,65,]},
        # max_lr is provided with dict, and the key of dict is the name of parameter group, value is their max learning rate respectively.
        # then parameters in the named group will use the that max_lr.
        # you can specify warmup_step, lr_reduce_factor, min_lr following like max_lr.
        ## remember: the following name can be user defined, that is, you don't have to name it with weight or other, you can group your parameters in the first three layers and name it "1", and the last four layers with name "2", the rest in the middle with name "3".
        ## then: the max_lr parameter would be : max_lr = {"1":1,"2":2,"3":3,"default":10}
        ## if you pass max_lr, warmup_step, lr_reduce_factor, min_lr as dict, then if any parameter with `group_name` not in the dict, the value with "default" key will be used
        # here is a toy example:
        # weight_p, bias_p = [],[]
        # for name, p in net.named_parameters():
        #     if "bias" in name:
        #         bias_p += [p]
        #     if "weight" in name:
        #         weight_p += [p]
        # optimizer = torch.optim.Adam([
        #  {"params":weight_p,"lr":weight_lr,"weight_decay":weight_decay,"group_name":"weight"},
        #  {"params":bias_p,"lr":bias_lr,"weight_decay":bias_decay,"group_name":"bias"}
        # ])
        # optimizer = NoamOpt(
        # optimzer = optimizer,
        # init_lr = 0,
        # max_lr = {"weight":1e-3,"bias":1e-4},
        # warmup_step = 5000,
        # lr_reduce_factor = {"weight":0.5,"bias":0.1},
        # ...
        # )
    ):
        self.optimizer = optimizer
        self._step = 0
        self._init_lr = init_lr
        self._max_lr = max_lr
        self._warmup_step = warmup_step
        self._lr_reduce_factor = lr_reduce_factor
        self._min_lr = min_lr
        self._best = best
        # direction is True: accuracy (or other) higher is better. if False, then lower is better
        self._direction = direction
        self._patience = patience
        self._cooldown = cooldown
        # if count down go to zero, then reduce learning rate : lr *= lr_reduce factor
        self._count_down = patience
        # do not record best when cd is not zero
        self._cd = cooldown
        self._threshold = threshold
        self._thresholdmode = thresmode
        self._scheduled_epoch = scheduled_epoch

        assert (
            "default" in max_lr.keys()
        ), "max_lr keys should contain 'default', but got only %s" % (max_lr.keys())
        assert isinstance(
            warmup_step, int
        ), "warmup_step keys should be type of int, but got %s" % (type(warmup_step))
        assert (
            "default" in max_lr.keys()
        ), "max_lr keys should contain 'default', but got only %s" % (max_lr.keys())
        assert "default" in lr_reduce_factor.keys(), (
            "lr_reduce_factor keys should contain 'default', but got only %s"
            % (lr_reduce_factor.keys())
        )
        assert (
            "default" in min_lr.keys()
        ), "min_lr keys should contain 'default', but got only %s" % (min_lr.keys())
        assert (
            "default" in scheduled_epoch.keys()
        ), "scheduled_epoch keys should contain 'default', but got only %s" %(scheduled_epoch.keys())
        for p in self.optimizer.param_groups:
            assert (
                "group_name" in p.keys()
            ), "Expected optimizer parameter groups should have key `group_name` but not found"

        self._lr_reduce_factor_count = {}
        self._lr_reduce_factor_count_update = {}
        for key in lr_reduce_factor.keys():
            self._lr_reduce_factor_count[key] = 0
            self._lr_reduce_factor_count_update[key] = False

        assert (self._thresholdmode == "abs") or (self._thresholdmode == "rel"), (
            "Expected thresmode to be one of 'abs' or 'rel', but got %s"
            % (self._threshold)
        )

    def step(self, *, best = None, epoch = None,):
        "Update parameters and rate"
        if best is None and epoch is None:
            self._step += 1
            self.rate()
            if (self._step <= self._warmup_step) & (
                (self._step * 10) % self._warmup_step == 0
            ):
                print(
                    "Warmup schedule reach %d / %d" % (self._step, self._warmup_step,)
                )
        elif epoch is not None:
            if epoch in list(self._scheduled_epoch.values())[0]:
                self.rate(lr_reduce=True)
                for name in self._lr_reduce_factor.keys():
                    lr_reduce_factor = (
                        self._lr_reduce_factor[name]
                        if name in self._lr_reduce_factor.keys()
                        else self._lr_reduce_factor["default"]
                    )
                    lr_reduce_factor_count = (
                        self._lr_reduce_factor_count[name]
                        if name in self._lr_reduce_factor_count.keys()
                        else self._lr_reduce_factor_count["default"]
                    )
                    max_lr = (
                        self._max_lr[name]
                        if name in self._max_lr.keys()
                        else self._max_lr["default"]
                    )
                    rate = max_lr * (
                        lr_reduce_factor ** lr_reduce_factor_count
                    )
                    print("""
                            Reduce learning rate to %g
                            """ % (rate))
        elif best is not None and self._step > self._warmup_step:
            if self._cd == 0:
                if self._thresholdmode == "abs":
                    if (self._direction & (best < (self._best - self._threshold))) or (
                        (not self._direction) & (best > (self._best + self._threshold))
                    ):
                        self._count_down -= 1
                        if self._count_down == 0:
                            self.rate(lr_reduce=True)
                            self._count_down = self._patience
                            for name in self._lr_reduce_factor.keys():
                                lr_reduce_factor = (
                                    self._lr_reduce_factor[name]
                                    if name in self._lr_reduce_factor.keys()
                                    else self._lr_reduce_factor["default"]
                                )
                                lr_reduce_factor_count = (
                                    self._lr_reduce_factor_count[name]
                                    if name in self._lr_reduce_factor_count.keys()
                                    else self._lr_reduce_factor_count["default"]
                                )
                                max_lr = (
                                    self._max_lr[name]
                                    if name in self._max_lr.keys()
                                    else self._max_lr["default"]
                                )
                                rate = max_lr * (
                                    lr_reduce_factor ** lr_reduce_factor_count
                                )
                                print("""
                                        Reduce learning rate to %g
                                        """ % (rate))
                    elif (
                        self._direction and (best >= (self._best + self._threshold))
                    ) or (
                        (not self._direction)
                        and (best <= (self._best - self._threshold))
                    ):
                        self._best = best
                        self._cd = self._cooldown
                        self._count_down = self._patience
                elif self._thresholdmode == "rel":
                    if (
                        self._direction & (best < (self._best * (1 + self._threshold)))
                    ) or (
                        (not self._direction)
                        & (best > (self._best * (1 + self._threshold)))
                    ):
                        self._count_down -= 1
                        if self._count_down == 0:
                            self.rate(lr_reduce=True)
                            for name in self._lr_reduce_factor.keys():
                                lr_reduce_factor = (
                                    self._lr_reduce_factor[name]
                                    if name in self._lr_reduce_factor.keys()
                                    else self._lr_reduce_factor["default"]
                                )
                                lr_reduce_factor_count = (
                                    self._lr_reduce_factor_count[name]
                                    if name in self._lr_reduce_factor_count.keys()
                                    else self._lr_reduce_factor_count["default"]
                                )
                                max_lr = (
                                    self._max_lr[name]
                                    if name in self._max_lr.keys()
                                    else self._max_lr["default"]
                                )
                                rate = max_lr * (
                                    lr_reduce_factor ** lr_reduce_factor_count
                                )
                                print("""
                                        Reduce learning rate to %g
                                        """ % (rate))
                            self._count_down = self._patience

                    elif (
                        self._direction
                        and (best >= (self._best * (1 + self._threshold)))
                    ) or (
                        (not self._direction)
                        and (best <= (self._best * (1 + self._threshold)))
                    ):
                        self._best = best
                        self._cd = self._cooldown
                        self._count_down = self._patience
            else:
                self._cd -= 1
        self.optimizer.step()
        return 0

    def rate(self, lr_reduce=False):
        "Implement `lrate` above"
        for p in self.optimizer.param_groups:
            name = p["group_name"]
            init_lr = (
                self._init_lr[name]
                if name in self._init_lr.keys()
                else self._init_lr["default"]
            )
            warmup_step = self._warmup_step
            max_lr = (
                self._max_lr[name]
                if name in self._max_lr.keys()
                else self._max_lr["default"]
            )

            min_lr = (
                self._min_lr[name]
                if name in self._min_lr.keys()
                else self._min_lr["default"]
            )

            if self._step <= warmup_step:
                rate = self._step / warmup_step * (max_lr - init_lr) + init_lr
                p['lr'] = rate

            elif lr_reduce:
                lr_reduce_factor = (
                    self._lr_reduce_factor[name]
                    if name in self._lr_reduce_factor.keys()
                    else self._lr_reduce_factor["default"]
                )
                is_lr_reduce_factor_count_updated = (
                    self._lr_reduce_factor_count_update[name]
                    if name in self._lr_reduce_factor_count_update.keys()
                    else self._lr_reduce_factor_count_update["default"]
                )
                if not is_lr_reduce_factor_count_updated:
                    if name in self._lr_reduce_factor_count.keys():
                        self._lr_reduce_factor_count[name] += 1
                        self._lr_reduce_factor_count_update[name] = True
                    else:
                        self._lr_reduce_factor_count["default"] += 1
                        self._lr_reduce_factor_count_update["default"] = True
                lr_reduce_factor_count = (
                    self._lr_reduce_factor_count[name]
                    if name in self._lr_reduce_factor_count.keys()
                    else self._lr_reduce_factor_count["default"]
                )
                rate = max_lr * (lr_reduce_factor ** lr_reduce_factor_count)
                if rate < min_lr:
                    rate = min_lr
                p['lr'] = rate
        for p in self.optimizer.param_groups:
            name = p["group_name"]
            self._lr_reduce_factor_count_update[name if name in self._lr_reduce_factor_count_update.keys() else "default"] = False 

        return 0

